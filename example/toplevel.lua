-- a minimal exmaple of using xdg-shell for creating a toplevel window with wau

local wau = require("wau")
wau:require("protocol.xdg-shell")

-- something we will need later

local helpers = require("helpers") -- helpers.so should be built already
local lgi = require("lgi")
local GLib = lgi.GLib
local cairo = lgi.cairo

-- connect + basic vars

local display = wau.wl_display.connect()
local registry = display:get_registry()

local width = 200
local height = 200
local stride = width * 4
local size = stride * height

-- registering globals; the usual stuff

local comp, seat, shm, xdg, output
registry:add_listener {
    ["global"] = function(_, name, interface, version)
        if interface == "wl_output" then
            output = registry:bind(name, wau.wl_output, version)
        elseif interface == "wl_compositor" then
            comp = registry:bind(name, wau.wl_compositor, version)
        elseif interface == "wl_shm" then
            shm = registry:bind(name, wau.wl_shm, version)
        elseif interface == "wl_seat" then
            seat = registry:bind(name, wau.wl_seat, version)
        elseif interface == "xdg_wm_base" then
            xdg = registry:bind(name, wau.xdg_wm_base, version)
        end
    end
}
display:roundtrip()
assert(comp and shm and seat and output and xdg, "Couldn't load globals")

-- a dumb example of handeling input

local pointer_listener = {
    ["motion"] = function(...) print("pointer move", ...) end,
    ["button"] = function(...) print("pointer click", ...) end,
}

local kb_listener = {
    ["key"] = function(...) print("key", ...) end
}

seat:add_listener {
    ["capabilities"] = function(_, c)
        if c & wau.wl_seat.Capability.POINTER ~= 0 then
            local pointer = seat:get_pointer()
            pointer:add_listener(pointer_listener)
        end
        if c & wau.wl_seat.Capability.KEYBOARD ~= 0 then
            local keyboard = seat:get_keyboard()
            keyboard:add_listener(kb_listener)
        end
    end
}

-- getting our dummy buffer

local function get_buffer()
    local fd, data = helpers.allocate_shm(size)
    local mypool = shm:create_pool(fd, size)
    local mybuffer = mypool:create_buffer(0, width, height, stride, 0)
    local cairo_surface = cairo.ImageSurface.create_for_data(data,
        cairo.Format.ARGB32, width, height, 4 * width)
    local cr = cairo.Context(cairo_surface)
    cr:set_source_rgba(1, 0, 0, 0.6)
    cr:paint()
    return mybuffer
end

-- setting up the window

xdg:add_listener { ["ping"] = wau.xdg_wm_base.pong }

local surface = comp:create_surface()
local xdg_surface = xdg:get_xdg_surface(surface)

xdg_surface:add_listener {
    ["configure"] = function(_, s)
        xdg_surface:ack_configure(s)
        local mybuffer = get_buffer()
        surface:attach(mybuffer, 0, 0)
        surface:commit()
    end
}

local xdg_toplevel = xdg_surface:get_toplevel()
xdg_toplevel:set_title("🐶 wau")
            :set_app_id("superwichtig")

surface:commit()

-- a more sane example of an actual mainloop, no `while true`

GLib.timeout_add(GLib.PRIORITY_DEFAULT, 20, function()
    display:roundtrip()
    return true
end)


local mainloop = GLib.MainLoop(nil, nil)
mainloop:run()

