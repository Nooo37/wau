--- Every object you will encounter is actually a `wl_proxy` object with a different given set of methods (depending on its interface).
    -- Thus it inherits all the `wl_proxy` methods - most notable the `add_listener` method.
    -- The different/variable set of methods available to an object is defined by the @{wl_interface} that the object has.
    -- The "to string" behavior of a proxy follows the wayland convention (for example similar to `wl_registry@2`)
-- @usage
    -- local wau = require("wau")
    -- local display = wau.wl_display.connect(nil)
    -- local registry = display:get_registry()
    -- print(display:get_id(), display:get_class(), display) -- the ID of the dipslay is always 1
    -- print(registry:get_id(), registry:get_class(), registry)
-- @classmod wl_proxy
-- @alias M

local ffi = require("cffi")

local wl_interface = require("wau.core.wl_interface")
local raw = require("wau.core.raw")

local M = { mt = {}, __events = {}, __data = {} }

-- private helper functions

local function get_identifier_for(proxy)
    return proxy:get_id()
end

local function get_callback_table_for(proxy, name)
    local id = get_identifier_for(proxy)
    M.__events[id] = M.__events[id] or {}
    local t = M.__events[id]
    t[name] = t[name] or {}
    return t[name]
end

local function get_proxy_safe(np, next_can_be_nil)
   if next_can_be_nil and np == ffi.nullptr then
       return nil
   else
       return ffi.cast("struct wl_proxy*", np)
   end
end


local function parse_args(proxy, message, args)
    local next_can_be_nil = false
    local signature = ffi.string(message.signature)
    local i = 0
    local lua_args = { proxy }
    for j=1,#signature do
        local c = signature:sub(j, j)
        if c == "u" or c == "i" or c == "f" or c == "h" then
            table.insert(lua_args, args[i][c])
            i = i + 1
        elseif c == "s" then
            table.insert(lua_args, ffi.string(args[i].s))
            next_can_be_nil = false
            i = i + 1
        elseif c == "o" or c == "n" then
            local new_proxy = get_proxy_safe(args[i].o, next_can_be_nil)
            if c == "n" then
                raw.wl_proxy_add_dispatcher(new_proxy, M.dispatcher, nil, nil)
            end
            table.insert(lua_args, new_proxy)
            next_can_be_nil = false
            i = i + 1
        elseif c == "?" then
            next_can_be_nil = true
        end
        -- TODO what to do with version info
    end
    return lua_args
end

-- wl_proxy methods

function M.dispatcher_func(_, proxy, _, message, args)
    local event_name = ffi.string(message.name)
    proxy = ffi.cast("struct wl_proxy*", proxy)
    local lua_args = parse_args(proxy, message, args)
    local event_callbacks = get_callback_table_for(proxy, event_name)
    for _, func in ipairs(event_callbacks) do
        local success, err = pcall(func, table.unpack(lua_args))
        if not success then
            io.stderr:write("Error calling callback function: ", tostring(err), "\n")
        end
    end
    return 0
end

M.dispatcher = ffi.cast("wl_dispatcher_func_t", M.dispatcher_func)

--- Get the class of the proxy
-- @treturn string The class name
function M:get_class()
    return ffi.string(raw.wl_proxy_get_class(self))
end

--- Get the ID of the proxy
-- @treturn int The ID of the proxy
function M:get_id()
    return raw.wl_proxy_get_id(self)
end

-- marshalling methods

local function return_new_proxy(obj)
    local o = ffi.cast("struct wl_proxy*", obj)
    if o == ffi.nullptr then return nil end
    raw.wl_proxy_add_dispatcher(o, M.dispatcher, nil, nil)
    return o
end

M.setup_new_proxy = return_new_proxy

function M:marshal(opcode, ...)
    raw.wl_proxy_marshal(self, opcode, ...)
end

function M:marshal_constructor(opcode, iface, ...)
    local id = raw.wl_proxy_marshal_constructor(self, opcode, iface, nil, ...)
    return return_new_proxy(id)
end

function M:marshal_constructor_versioned(opcode, iface, version, name, iface_name)
    local id = raw.wl_proxy_marshal_constructor_versioned(
            self, opcode, iface, version, name, iface_name, version, nil)
    return return_new_proxy(id)
end

-- event related methods

--- Add event listeners to the proxy.
-- @param listener A table of event listener functions whose key is the event name. The first parameter to the function is `self` (the object that received the event) followed by the parameters as specified in the protocol. For in action see  @{wl_interface}
-- - test
-- - huch
-- @usage
-- my_proxy:add_listener {
    --    ["event_name"] = function(self, b) print(b) end,
    --    ["another_event"] = function(self) error("hey") end
    -- }
function M:add_listener(listener)
    for event_name, func in pairs(listener) do
        local event_callbacks = get_callback_table_for(self, event_name)
        table.insert(event_callbacks, func)
    end
end

function M:connect_event(event_name, func)
    local callbacks = get_callback_table_for(self, event_name)
    table.insert(callbacks, func)
end

function M:disconnect_event(event_name, func)
    local callbacks = get_callback_table_for(self, event_name)
    local idx = nil
    for i, f in ipairs(callbacks) do
        if f == func then
            idx = i
        end
    end
    if idx then
        table.remove(callbacks, idx)
    end
end

-- metatable

function M.mt.__tostring(self)
    return ("<%s@%d>"):format(self:get_class(), self:get_id())
end

function M.mt.__index(self, k)
    if M[k] then return M[k] end
    local iface_name = self:get_class()
    local iface = wl_interface.__private[iface_name]
    return iface[k]
end

ffi.metatype("struct wl_proxy", M.mt)

return M
