local wau = require("wau")

local display = wau.wl_display.connect(os.getenv("SOCKET"))
assert(display, "Failed to connect to wayland compositor")

local registry = display:get_registry()

local output, compositor, shm
registry:add_listener {
    ["global"] = function(_, _, interface, version)
	if interface == "wl_output" then
            output = registry:bind(name, wau.wl_output, version)
        elseif interface == "wl_compositor" then
            compositor = registry:bind(name, wau.wl_compositor, version)
        elseif interface == "wl_shm" then
            shm = registry:bind(name, wau.wl_shm, version)
    	end
    end
}
display:roundtrip()

assert(output and compositor and shm, "Failed to bind wl_output, wl_compositor or/and wl_shm")

