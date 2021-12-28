local wau = require("wau")

wau:require("wlr-foreign-toplevel-management-unstable-v1")


local display = wau.wl_display.connect()
assert(display, "Failed to connect to wayland compositor")

display:roundtrip()

local registry = display:get_registry()

local toplevel_manager
registry:connect_event("global",function(self, name, iface, version)
    if iface == "zwlr_foreign_toplevel_manager_v1" then
        toplevel_manager = self:bind(name,
            wau.zwlr_foreign_toplevel_manager_v1, version)
    end
end)

display:roundtrip()
assert(toplevel_manager, "Failed to bind foreign toplevel manager")

local toplevel_listener = {
    ["title"] = function(_, title) print("New title!", title) end,
    ["app_id"] = function(_, app_id) print("New app_id!", app_id) end,
    ["closed"] = function(self) print("Oh no it closed!", self) end,
    ["parent"] = function(self, p) print("New parent!", self, p) end,
}

toplevel_manager:add_listener {
    ["finished"] = function() error("Breakup with the compositor! :(") end,
    ["toplevel"] = function(_, tl) tl:add_listener(toplevel_listener) end,
}

while true do
    display:roundtrip()
end

display:disconnect()

