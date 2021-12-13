-- Takes a screenshot of an output using the wlr-screencopy protocol
-- and writes it into test.png using cairo through lgi

local wau = require("wau")
wau:require("protocol.wayland")
wau:require("protocol.wlr-screencopy-unstable-v1")

local lgi = require("lgi")
local cairo = lgi.cairo

local display = wau:connect()
local registry = display:get_registry()

-- register globals

local output, shm, screencopy_manager
registry:connect_event("global", function(name, interface, version)
    if interface == "wl_output" then
        output = registry:bind(name, wau.wl_output, version)
    elseif interface == "wl_shm" then
        shm = registry:bind(name, wau.wl_shm, version)
    elseif interface == "zwlr_screencopy_manager_v1" then
        screencopy_manager =
            registry:bind(name, wau.zwlr_screencopy_manager_v1, version)
    end
end)
display:roundtrip()
assert(output and shm, "Couldn't load globals wl_output or wl_shm")
assert(screencopy_manager, "Couldn't load global zwlr_screencopy_manager")

-- caputre a frame into shared memory, read that back into a cairo surface

local fd, data, mybuffer
local width, height, stride
local done = false

local myframe = screencopy_manager:capture_output(0, output)

myframe:connect_event("buffer", function(format, w, h, s)
    assert(format == wau.wl_shm.Format.ARGB8888) -- for the cairo surface
    width = w
    height = h
    stride = s
    local size = height * stride
    fd, data = wau.helpers.allocate_shm(size)
    local mypool = shm:create_pool(fd, size)
    mybuffer = mypool:create_buffer(0, width, height, stride, 0)
    myframe:copy(mybuffer)
end)

myframe:connect_event("ready", function()
    -- "ready" is emitted after "buffer" so the info should be ready here
    local surf = cairo.ImageSurface.create_for_data(data,
        cairo.Format.ARGB32, width, height, stride)
    surf:write_to_png("test.png")
    done = true
end)

myframe:connect_event("failed", function()
    error("Failed to take the screenshot!")
end)

while not done do
    display:roundtrip()
end

