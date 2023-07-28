local xml2lua = require("xml2lua")
local handler = require("xmlhandler.tree")

local function to_camel_case(s)
    return s:gsub("_(.)", string.upper):gsub("^(.)", string.upper)
end

local function to_upper_case(s)
    return s:upper()
end

-- parsing

local parser = {}

function parser.get_field(t, field)
    -- the xml parser either sets
    -- t["field"] = myfield; if there is only one occurence of "field" in t
    -- t["field"] = { myfield1, myfield2, ... }; if there are multiple occurences
    -- or t["field"] = nil; if there are none
    -- In this function we are making sure that we get a list in any case
    return t[field] and (#t[field] == 0 and {t[field]} or t[field]) or {}
end

function parser.description(handle)
    if not handle then return nil end
    local result = handle._attr or {}
    result.long = handle[1]
    return result
end

function parser.arg(handle)
    if not handle._attr then error("Argument without attributes") end
    local result = handle._attr
    return result
end

function parser.request(handle)
    local result = handle._attr or {}
    result.description = parser.description(handle.description)
    result.args = {}
    local args = parser.get_field(handle, "arg")
    for i, arg in ipairs(args) do
        result.args[i] = parser.arg(arg)
    end
    return result
end

function parser.event(handle)
    local result = handle._attr or {}
    result.description = parser.description(handle.description)
    result.args = {}
    local args = parser.get_field(handle, "arg")
    for i, arg in ipairs(args) do
        result.args[i] = parser.arg(arg)
    end
    return result
end

function parser.enum(handle)
    local result = handle._attr or {}
    result.description = parser.description(handle.description)
    result.entries = {}
    local entries = parser.get_field(handle, "entry")
    for i, entry in ipairs(entries) do
        if not entry._attr then error("Enum entry without attributes") end
        result.entries[i] = entry._attr
    end
    return result
end

function parser.interface(handle)
    local result = handle._attr or {}
    result.description = parser.description(handle.description)
    result.requests = {}
    local requests = parser.get_field(handle, "request")
    for i, request in ipairs(requests) do
        result.requests[i] = parser.request(request)
    end
    result.events = {}
    local events = parser.get_field(handle, "event")
    for i, event in ipairs(events) do
        result.events[i] = parser.event(event)
    end
    result.enums = {}
    local enums = parser.get_field(handle, "enum")
    for i, enum in ipairs(enums) do
        result.enums[i] = parser.enum(enum)
    end
    return result
end

function parser.protocol(handle)
    local result = handle._attr or {}
    result.copyright = handle.copyright
    result.description = parser.description(handle.description)
    result.interfaces = {}
    local interfaces = parser.get_field(handle, "interface")
    for i, iface in ipairs(interfaces) do
        result.interfaces[i] = parser.interface(iface)
    end
    return result
end

-- printing

local function convert_type_to_signature(type_name, optional)
    local res = optional and "?" or ""
    if type_name == "int" then return res .. "i"
    elseif type_name == "string" then return res .. "s"
    elseif type_name == "fd" then return res .. "h"
    elseif type_name == "fixed" then return res .. "f"
    elseif type_name == "array" then return res .. "a"
    elseif type_name == "object" then return res .. "o"
    elseif type_name == "new_id" then return res .. "n"
    elseif type_name == "uint" then return res .. "u"
    else error("Couldn't resolve type", type_name) end
end

local function get_message_types(args)
    local types = "{ "
    for _, arg in ipairs(args) do
        if arg.type == "object" or arg.type == "new_id" then
            -- check if interface exists (what to do?)
            local iface = arg.interface
                and string.format("wau.%s", arg.interface)
                or "0"
            types = string.format("%s%s, ", types, iface)
        else
            types = types .. "0, "
        end
    end
    return types .. "}"
end

local function get_message_signature(mes)
    local signature = mes.since and mes.since or ""
    for _, arg in ipairs(mes.args) do
        signature = signature .. convert_type_to_signature(arg.type,
            arg["allow-null"] and arg["allow-null"] == "true")
    end
    if signature == "un" then signature = "usun" end -- TODO
    return signature
end

local printer = {
    include_comments = true,
    opcode_field = "_OpCode",
    indent = 0,
    indent_delta = 4,
}

function printer.indent_add()
    printer.indent = printer.indent + printer.indent_delta
    return printer
end

function printer.indent_sub()
    printer.indent = printer.indent - printer.indent_delta
    return printer
end

function printer.line(f, ...)
    if not f then f = "" end
    if f == "" then -- empty line without indent
        io.stdout:write("\n")
        return printer
    end
    local indent = ""
    for _=1,printer.indent do
        indent = string.format("%s ", indent)
    end
    f = string.format(f, ...)
    f = f:gsub("\n%s*", " ") -- no new lines in one line printed
    io.stdout:write("\n", indent, f)
    return printer
end

function printer.comment(s)
    if printer.include_comments then
        local toprint = s:gsub("^%s*", "-- "):gsub("\n%s*", "\n-- ")
        for line in (toprint ..'\n'):gmatch'(.-)\r?\n' do
            printer.line(line)
        end
    end
    return printer
end

function printer.message(mes)
    printer.line([[{]])
    printer.indent_add()
    printer.line([[name = "%s",]], mes.name)
    printer.line([[signature = "%s",]],
        get_message_signature(mes))
    printer.line([[types = %s,]],
        get_message_types(mes.args))
    if mes.type then
        printer.line([[type = "%s"]], mes.type)
    end
    printer.indent_sub()
    printer.line([[},]])
end

function printer.enum(enum)
    printer.line([[["%s"] = {]], enum.name)
    printer.indent_add()
    for _, entry in ipairs(enum.entries) do
        printer.line([[["%s"] = %s,]], entry.name, entry.value)
    end
    printer.indent_sub()
    printer.line([[},]])
end

function printer.interface(iface)
    printer.line([[--- %s]], iface.description.summary or iface.name)
    if iface.description.long then
        printer.line([[--]])
        printer.comment(iface.description.long)
    end
    printer.line([[-- @type %s]], iface.name)
    printer.line([[wau.%s:init {]], iface.name)
    printer.indent_add()
    -- basics
    printer.line([[name = "%s",]], iface.name)
    printer.line([[version = %s,]], iface.version)
    -- methods
    printer.line([[methods = {]])
    printer.indent_add()
    for _, request in ipairs(iface.requests) do
        printer.line([[--- %s]], request.description.summary or request.name)
        if request.description.long then
            printer.line([[--]])
            printer.comment(request.description.long)
        end
        printer.line([[-- @function %s:%s]], iface.name, request.name)
        local returns = false
        for _, arg in ipairs(request.args) do
            if arg.type ~= "new_id" then
                printer.line([[-- @tparam %s %s%s]], arg.type == "object" and arg.interface or arg.type, arg.name,
                    arg.summary and " " .. arg.summary or "")
            else
                returns = true
                printer.line([[-- @treturn %s]], arg.interface or "object")
            end
        end
        if not returns then
            printer.line([[-- @treturn %s self]], iface.name)
        end
        printer.message(request)
    end
    printer.indent_sub()
    printer.line([[},]])
    -- events
    printer.line([[events = {]])
    printer.indent_add()
    for _, event in ipairs(iface.events) do
        printer.line([[--- %s]], event.description.summary or event.name)
        if event.description.long then
            printer.line([[--]])
            printer.comment(event.description.long)
        end
        printer.line([[-- @event %s:%s]], iface.name, event.name)
        for _, arg in ipairs(event.args) do
            printer.line([[-- @tparam %s %s%s]], (arg.type == "object" or arg.type == "new_id")
                and arg.interface or arg.type, arg.name,
                arg.summary and " " .. arg.summary or "")
        end
        printer.message(event)
    end
    printer.indent_sub()
    printer.line([[},]])
    -- enums
    printer.line([[enums = {]])
    printer.indent_add()
    for _, enum in ipairs(iface.enums) do
        printer.line([[--- %s]], enum.description and enum.description.summary or enum.name)
        if enum.description and enum.description.long then
            printer.line([[--]])
            printer.comment(enum.description.long)
        end
        printer.line([[-- @enum %s.%s]], iface.name, to_camel_case(enum.name))
        for _, entry in ipairs(enum.entries) do
            printer.line([[-- @param %s %s%s]],
                to_upper_case(entry.name),
                entry.value,
                entry.summary and " " .. entry.summary or "")
        end
        printer.enum(enum)
    end
    printer.indent_sub()
    printer.line([[},]])
    -- method opcode
    printer.line([[methods_opcode = {]])
    printer.indent_add()
    for i, request in ipairs(iface.requests) do
        printer.line([[["%s"] = %s,]], request.name, i - 1)
    end
    printer.indent_sub()
    printer.line([[},]])

    printer.indent_sub()
    printer.line([[}]])
    printer.line()
end

function printer.protocol(protocol)
    printer.line([[--- %s]], protocol.name)
    printer.line([[-- @module %s]], protocol.name)

    if protocol.copyright then
        printer.line()
        printer.comment(protocol.copyright)
    end

    printer.line([[return function(wau)]])
    printer.line()
    printer.line([[local interfaces = {]])
    printer.indent_add()
    for _, iface in ipairs(protocol.interfaces) do
        printer.line([["%s",]], iface.name)
    end
    printer.indent_sub()
    printer.line([[}]])
    printer.line()
    printer.line([[for _, iface in ipairs(interfaces) do]])
    printer.indent_add()
    printer.line([[wau[iface] = wau.wl_interface.new()]])
    printer.indent_sub()
    printer.line([[end]])
    printer.line()
    for _, iface in ipairs(protocol.interfaces) do
        printer.interface(iface)
    end
    printer.line([[end]])
end

-- main

local function main(arg)
    local content
    for line in io.lines() do
        content = content and string.format("%s\n%s", content, line) or line
    end
    assert(content)

    -- check command line arguments
    for i, a in ipairs(arg) do
        if a == "-nc" or a == "--no-comment" then
            printer.include_comments = false
        elseif a == "-i" or a == "--indent" then
            if arg[i + 1] and tonumber(arg[i + 1]) then
                printer.indent_delta = tonumber(arg[i + 1])
            end
        end
    end

    local xml_parser = xml2lua.parser(handler)
    xml_parser:parse(content)

    assert(handler.root.protocol, "Failed to parse protocol")
    local protocol = parser.protocol(handler.root.protocol)

    if printer.include_comments then
        io.stdout:write("-- Auto generated by the wau-scanner v0\n")
    end
    printer.protocol(protocol)
    io.stdout:write("\n")
end

main(arg)
