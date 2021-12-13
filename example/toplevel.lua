-- a minimal exmaple of using xdg-shell for creating a toplevel window with wau

local wau = require("wau")
wau:require("protocol.wayland")
wau:require("protocol.xdg-shell")

local lgi = require("lgi")
local cairo = lgi.cairo

local display = wau:connect()
local registry = display:get_registry()

local width = 200
local height = 200
local stride = width * 4
local size = stride * height

-- registering globals; the usual stuff

local comp, seat, shm, xdg, output
registry:connect_event("global", function(name, interface, version)
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
end)
display:roundtrip()
assert(comp and shm and seat and output and xdg, "Couldn't load globals")

-- a dumb example of handeling input

seat:connect_event("capabilities", function(c)
    if c & wau.wl_seat.Capability.POINTER ~= 0 then
        local pointer = seat:get_pointer()
        pointer:connect_event("motion", function(...)
            print("pointer", ...)
        end)
    end
    if c & wau.wl_seat.Capability.KEYBOARD ~= 0 then
        local keyboard = seat:get_keyboard()
        keyboard:connect_event("key", function(...)
            print("click", ...)
        end)
    end
end)

-- getting our dummy buffer

local function get_buffer()
    local fd, data = wau.helpers.allocate_shm(size)
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

xdg:connect_event("ping", function(s)
    print("ping", s)
    xdg:pong(s)
end)

local surface = comp:create_surface()
local xdg_surface = xdg:get_xdg_surface(surface)

xdg_surface:connect_event("configure", function(s)
    print("configure", s)
    xdg_surface:ack_configure(s)
    local mybuffer = get_buffer()
    surface:attach(mybuffer, 0, 0)
    surface:commit()
end)

local xdg_toplevel = xdg_surface:get_toplevel()
xdg_toplevel:set_title("🐶 wau")
            :set_app_id("superwichtig")

surface:commit()

while true do display:roundtrip() end

