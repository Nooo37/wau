local wau = require("wau")

local display = wau.wl_display.connect(os.getenv("SOCKET"))
assert(display, "Failed to connect to wayland compositor")

local registry = display:get_registry()

local output, compositor, shm
registry:add_listener {
    ["global"] = function(_, name, interface, version)
        if interface == "wl_shm" then
            shm = registry:bind(name, wau.wl_shm, version)
    	end
    end
}

display:roundtrip()

assert(shm, "Failed to bind wl_shm")

local argb8888 = false
shm:add_listener {
    ["format"] = function(_, format)
	argb8888 = argb8888 or (format == wau.wl_shm.Format.ARGB8888)
    end
}

display:roundtrip()

assert(argb8888, "Couldn't find ARGB8888 SHM format")
