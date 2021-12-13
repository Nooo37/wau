# wau

This should work with Lua 5.3+. By default it builds with 5.3 instead of 5.4 because the examples depend on [lgi](https://github.com/pavouk/lgi/).

These aren't 1-to-1 bindings to libwayland. Especially events aren't handled by adding a event listener struct but instead through a more AwesomeWM-like syntax:

```lua
myobject:connect_event("eventname", function(param1, param2, anotherone)
    -- do stuff here
end)
```

Do `lua wau-scanner.lua < my-wayland-protocol.xml > my-wayland-protocol.lua` to generate the protocol glue code.

Read the examples or read through the [wayland protocols](https://wayland.app/protocols/) to get a grasp.

> wau wau     *~ 🐕*

