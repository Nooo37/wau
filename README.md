# wau

This should work with Lua 5.3+. By default it builds with 5.3 instead of 5.4 because the examples depend on [lgi](https://github.com/pavouk/lgi/).

These aren't 1-to-1 bindings to libwayland. Especially events aren't handled by adding a event listener struct but instead through a more AwesomeWM-like syntax:

```lua
myobject:connect_event("eventname", function(param1, param2, anotherone)
    -- do stuff here
end)
```

Wau-scanner generates the glue code necessary for different protcols. Do `lua wau-scanner.lua < my-wayland-protocol.xml > my-wayland-protocol.lua` to generate them.

Read the examples or read through the [wayland protocols](https://wayland.app/protocols/) to get a grasp regarding wayland otherwise.

## Installation

You can install the whole thing through luarocks. The only downside is that I don't know how to compile with the requested lua version there so make sure to install it for Lua 5.3 for now.

```sh
sudo luarocks install --server=https://luarocks.org/dev wau --lua-version 5.3
```

That should add the ability to use wau through `require("wau")` but also to use the protocol scanner like a normal program through something like `wau-scanner < my-wayland-protocol.xml > my-wayland-protocol.lua`.

> wau wau     ~ 🐕

