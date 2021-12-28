-- probably the simplest program to write, lists all bindable globals
local wau = require("wau")

-- this is an example of passing the server path to the connect function
-- in this case it is redundant since it uses the default path anyway
local path_to_server = os.getenv("XDG_RUNTIME_DIR") .. "/wayland-1"
local display = wau.wl_display.connect(path_to_server)

local registry = display:get_registry()
registry:connect_event("global", function(_, _, interface, version)
    print(interface, version)
end)

display:roundtrip()

