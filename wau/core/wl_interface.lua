--- All `wl_interface` that are loaded from protocols through `wau.require(x)` are all fields in the wau table.
    -- For example `wau.wl_pointer` is the interface for a wayland pointer.
-- @classmod wl_interface
-- @alias M

local ffi = require("cffi")
local raw = require("wau.core.raw")

ffi.cdef[[
void *malloc(int64_t);
void free(void *);
]]

local M = { mt = {}, __private = {} }

-- internal libwayland representation

local function parse_types(types)
    if #types == 0 then
        local ptr = ffi.C.malloc(1 * ffi.sizeof("struct wl_interface*"))
        local dummy_types = ffi.cast("struct wl_interface**", ptr)
        dummy_types[0] = ffi.nullptr
        return dummy_types
    else
        local ptr = ffi.C.malloc(#types * ffi.sizeof("struct wl_interface*"))
        local result = ffi.cast("struct wl_interface**", ptr)
        for i, interface in ipairs(types) do
            result[i - 1] = interface == 0 and ffi.nullptr or interface
        end
        return result
    end
end

local function parse_messages(messages)
    if #messages == 0 then return ffi.nullptr end
    local pointer = ffi.C.malloc(#messages * ffi.sizeof("struct wl_message"))
    local result = ffi.cast("struct wl_message*", pointer)
    for i, message in ipairs(messages) do
        result[i - 1].name = message.name
        result[i - 1].signature = message.signature
        result[i - 1].types = parse_types(message.types)
    end
    return result
end

-- setting up methods

local mtype = {
    CONSTRUCTOR = 0,
    VERSIONED_CONSTRUCTOR = 1,
    DESTRUCTOR = 2,
    METHOD = 3,
}

local function get_method_type(method_data)
    local signature = method_data.signature
    local n_idx = signature:find("n")
    if n_idx and method_data.types[n_idx] ~= nil then
        return mtype.CONSTRUCTOR
    elseif n_idx and (method_data.types[n_idx] == nil or method_data.types[n_idx] == 0) then
        return mtype.VERSIONED_CONSTRUCTOR
    elseif method_data.type and method_data.type == "destructor" then
        return mtype.DESTRUCTOR
    else
        return mtype.METHOD
    end
end

local function translate_opcode_to_method(iface, opcode)
    local method_data = iface.methods[opcode + 1]
    local type = get_method_type(method_data)
    if type == mtype.METHOD then
        return function(other, ...)
            other:marshal(opcode, ...)
            return other
        end
    elseif type == mtype.CONSTRUCTOR then
        return function(other, ...)
            return other:marshal_constructor(opcode,
                method_data.types[1], ...)
        end
    elseif type == mtype.DESTRUCTOR then
        return function(other, ...)
            other:marshal(opcode, ...)
            raw.wl_proxy_destroy(other)
        end
    elseif type == mtype.VERSIONED_CONSTRUCTOR then
        return function(other, name, interface, version)
            return other:marshal_constructor_versioned(opcode,
                interface, version, name, interface.name)
        end
    end
end

local function setup_methods(table_to_set, iface)
    for i, method in ipairs(iface.methods) do
        table_to_set[method.name] = translate_opcode_to_method(iface, i - 1)
    end
end

-- setting up enums

local function to_camel_case(s)
    return s:gsub("_(.)", string.upper):gsub("^(.)", string.upper)
end

local function to_upper_case(s)
    return s:upper()
end

local function setup_enums(table_to_set, iface)
    for name, enum in pairs(iface.enums) do
        local n = to_camel_case(name)
        table_to_set[n] = {}
        for entry_name, entry_value in pairs(enum) do
            local entry_n = to_upper_case(entry_name)
            table_to_set[n][entry_n] = entry_value
        end
    end
end


-- module functions

function M.init(self, iface)
    self.name = iface.name
    self.version = iface.version
    self.method_count = #iface.methods
    self.event_count = #iface.events
    self.methods = parse_messages(iface.methods)
    self.events = parse_messages(iface.events)
    M.__private[iface.name] = iface
    -- getting info from iface table and also setting entries on that table
    setup_methods(iface, iface)
    setup_enums(iface, iface)
end

function M.new()
    local rpointer = ffi.C.malloc(ffi.sizeof("struct wl_interface"))
    return ffi.cast("struct wl_interface*", rpointer)
end

-- metatable

function M.mt.__index(self, k)
    if k == "init" then return M.init end
    local iface = ffi.string(self.name)
    return M.__private[iface][k]
end

function M.mt.__newindex(self, k, v)
    M.__private[ffi.string(self.name)][k] = v
end

function M.mt.__tostring(self)
    return ("<interface:%s:v%d>"):format(ffi.string(self.name), self.version)
end

function M.mt.__call()
    return M.new()
end

ffi.metatype("struct wl_interface", M.mt)

return M
