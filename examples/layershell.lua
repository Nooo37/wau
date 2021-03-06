--- a simple layershell example

-- loading protocols

local wau = require("wau")
wau:require("protocol.xdg-shell") -- layershell implicitly depends on xdg-shell
wau:require("protocol.wlr-layer-shell-unstable-v1")

-- something we need later on

local helpers = require("helpers") -- helpers.so should be built already
local lgi = require("lgi")
local cairo = lgi.cairo

-- connecting to the server

local display = wau.wl_display.connect()
assert(display, "Couldn't connect to the wayland server")

-- register globals

local registry = display:get_registry()
local output, comp, shm, layershell

registry:add_listener {
    ["global"] = function(_, name, interface, version)
        if interface == "wl_output" then
            output = registry:bind(name, wau.wl_output, version)
        elseif interface == "wl_compositor" then
            comp = registry:bind(name, wau.wl_compositor, version)
        elseif interface == "wl_shm" then
            shm = registry:bind(name, wau.wl_shm, version)
        elseif interface == "zwlr_layer_shell_v1" then
            layershell = registry:bind(name, wau.zwlr_layer_shell_v1, version)
        end
    end
}

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

local Anchor = wau.zwlr_layer_surface_v1.Anchor
mywidget:set_anchor(Anchor.RIGHT + Anchor.TOP)
        :set_margin(10, 10, 10, 10)
        :set_size(width, height)
        :add_listener { ["configure"] = wau.zwlr_layer_surface_v1.ack_configure }
        -- Same thing as doing this:
        --:add_listener { ["configure"] = function(self, s) self:ack_configure(s) end }

surface:commit()
display:roundtrip()

-- now that we got a surface, we need a buffer to attach to the surface

local fd, data = helpers.allocate_shm(size)
local mypool = shm:create_pool(fd, size)
local mybuffer = mypool:create_buffer(0, width, height, stride, 0)
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

