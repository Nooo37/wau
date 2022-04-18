-- a minimal exmaple of using xdg-shell for creating a toplevel window with wau

local wau = require("wau")
local helpers = require("helpers")
wau:require("protocol.xdg-shell")

local lgi = require("lgi")
local GLib = lgi.GLib
local cairo = lgi.cairo

local display = wau.wl_display.connect()
local registry = display:get_registry()

local width = 200
local height = 200
local stride = width * 4
local size = stride * height

-- registering globals; the usual stuff

local compositor, seat, shm, xdg, output
registry:add_listener {
    ["global"] = function(_, name, interface, version)
        if interface == "wl_output" then
            output = registry:bind(name, wau.wl_output, version)
        elseif interface == "wl_compositor" then
            compositor = registry:bind(name, wau.wl_compositor, version)
        elseif interface == "wl_shm" then
            shm = registry:bind(name, wau.wl_shm, version)
        elseif interface == "wl_seat" then
            seat = registry:bind(name, wau.wl_seat, version)
        elseif interface == "xdg_wm_base" then
            xdg = registry:bind(name, wau.xdg_wm_base, version)
            xdg:add_listener { ["ping"] = wau.xdg_wm_base.pong }
        end
    end
}
display:roundtrip()
assert(compositor and shm and seat and output and xdg, "Couldn't load globals")

-- get cursor surfaces by name

local function get_cursor_surface(name)
    local cursor_theme = wau.wl_cursor_theme.load(nil, 24, shm)
    local cursor = cursor_theme:get_cursor(name)
    local cursor_image = cursor.images[0]
    local cursor_buffer = cursor_image:get_buffer()
    local cursor_surface = compositor:create_surface()
    cursor_surface:attach(cursor_buffer, 0, 0)
    cursor_surface:commit()
    return cursor_surface, cursor_image
end

-- a dumb example of handeling input + setting the cursor

local cursor_surface, cursor_image = get_cursor_surface("cross")

local function dumb_log(eventname)
    return function(...) print(eventname, ...) end
end

local pointer_listener = {
    ["motion"] = dumb_log("pointer motion"),
    ["button"] = dumb_log("pointer click"),
    ["axis"] = dumb_log("pointer axis"),
    ["leave"] = dumb_log("pointer leave"),
    ["enter"] = function(self, serial, surface, x, y)
        -- set the cursor, otherwise it is undefined and up to the compositor
        self:set_cursor(serial, cursor_surface, cursor_image.hotspot_x,
            cursor_image.hotspot_y)
        dumb_log("pointer enter")(self, serial, surface, x, y)
    end,
}

local keyboard_listener = {
    ["key"] = dumb_log("keyboard key"),
    ["enter"] = dumb_log("keyboard focus"),
    ["leave"] = dumb_log("keyboard leave"),
}

seat:add_listener {
    ["capabilities"] = function(_, c)
        if c & wau.wl_seat.Capability.POINTER ~= 0 then
            local pointer = seat:get_pointer()
            pointer:add_listener(pointer_listener)
        end
        if c & wau.wl_seat.Capability.KEYBOARD ~= 0 then
            local keyboard = seat:get_keyboard()
            keyboard:add_listener(keyboard_listener)
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

local mainloop = GLib.MainLoop(nil, nil)
local running = true

local surface = compositor:create_surface()
surface:add_listener {
    ["enter"] = dumb_log("surface enters"),
    ["leave"] = dumb_log("surface leaves"),
}

local xdg_surface = xdg:get_xdg_surface(surface)
xdg_surface:add_listener {
    ["configure"] = function(self, s)
        self:ack_configure(s)
        local mybuffer = get_buffer()
        surface:attach(mybuffer, 0, 0)
        surface:commit()
    end,
}

local xdg_toplevel = xdg_surface:get_toplevel()
xdg_toplevel:add_listener {
    ["close"]= function(self)
        self:destroy()
        xdg_surface:destroy()
        running = false
        mainloop:quit()
    end
}
xdg_toplevel:set_title("🐶 wau")
            :set_app_id("org.no37.beispiel")

surface:commit()

-- a more sane example of an actual mainloop, no `while true`

GLib.timeout_add(GLib.PRIORITY_DEFAULT, 20, function()
    display:roundtrip()
    return running
end)

mainloop:run()

