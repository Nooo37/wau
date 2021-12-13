-- a simple layershell example

-- loading protocols

local wau = require("wau")
wau:require("protocol.wayland")
wau:require("protocol.xdg-shell") -- layershell implicitly depends on xdg-shell
wau:require("protocol.wlr-layer-shell-unstable-v1")

-- something we need later on

local lgi = require("lgi")
local cairo = lgi.cairo

-- connecting to the server

local display = wau:connect()
assert(display, "Couldn't connect to the wayland server")

-- register globals

local registry = display:get_registry()
local output, comp, shm, layershell
registry:connect_event("global", function(name, interface, version)
    if interface == "wl_output" then
        output = registry:bind(name, wau.wl_output, version)
    elseif interface == "wl_compositor" then
        comp = registry:bind(name, wau.wl_compositor, version)
    elseif interface == "wl_shm" then
        shm = registry:bind(name, wau.wl_shm, version)
    elseif interface == "zwlr_layer_shell_v1" then
        layershell = registry:bind(name, wau.zwlr_layer_shell_v1, version)
    end
end)
display:roundtrip()
assert(output and comp and shm, "Couldn't load wl_ output, compositor or shm")
assert(layershell, "Couldn't load layershell")

-- create the wl_surface and the layer shell surface

local width = 100
local height = 100
local stride = width * 4
local size = stride * height

local surface = comp:create_surface()
display:roundtrip()

local mywidget = layershell:get_layer_surface(surface, output,
    wau.zwlr_layer_shell_v1.Layer.TOP, "epicwau")

mywidget:set_anchor(mywidget.Anchor.RIGHT + mywidget.Anchor.TOP)
        :set_margin(10, 10, 10, 10)
        :set_size(width, height)
        :connect_event("configure", function(s) mywidget:ack_configure(s) end)

surface:commit()
display:roundtrip()

-- now that we got a surface, we need a buffer to attach to the surface

local fd, data = wau.helpers.allocate_shm(size)
local mypool = wau.wl_shm.create_pool(shm, fd, size)
local mybuffer = wau.wl_shm_pool.create_buffer(mypool, 0, width, height, stride, 0)
surface:attach(mybuffer, 0, 0)
surface:commit()

-- and finally we need something to draw on the buffer

local cairo_surface = cairo.ImageSurface.create_for_data(data,
    cairo.Format.ARGB32, width, height, 4 * width)
local cr = cairo.Context(cairo_surface)
cr:set_source_rgba(1, 0, 0, 0.6)
cr:paint()

-- no surfaces were harmed during the making of this example

surface:damage(0, 0, width, height)
surface:commit()
display:roundtrip()

-- our widget doesn't do anything so we can just sleep now

os.execute("sleep " .. tostring(1000 * 2))

