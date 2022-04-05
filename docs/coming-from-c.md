If you come from C and you did a little bit of wayland over there, you will find that most things are done very analogous.

Let's take a look at one of the most simple C libwayland examples straight from [the wayland book](https://wayland-book.com/registry/binding.html) - listing all globals:

```C
#include <stdint.h>
#include <stdio.h>
#include <wayland-client.h>

static void
registry_handle_global(void *data, struct wl_registry *registry,
		uint32_t name, const char *interface, uint32_t version)
{
	printf("interface: '%s', version: %d, name: %d\n",
			interface, version, name);
}

static void
registry_handle_global_remove(void *data, struct wl_registry *registry,
		uint32_t name)
{
	// This space deliberately left blank
}

static const struct wl_registry_listener
registry_listener = {
	.global = registry_handle_global,
	.global_remove = registry_handle_global_remove,
};

int
main(int argc, char *argv[])
{
	struct wl_display *display = wl_display_connect(NULL);
	struct wl_registry *registry = wl_display_get_registry(display);
	wl_registry_add_listener(registry, &registry_listener, NULL);
	wl_display_roundtrip(display);
	return 0;
}
```

# Direct translation

How would we achieve that with lua and wau?

First, we will translate the code above as accurately as possible to lua:

```lua
local wau = require("wau")

local function registry_handle_global(registry, name, interface, version)
    print("interface: " .. interface .. ", version: " .. tostring(version) .. ", name: " .. name)
end

local function registry_handle_global_remove(registry, name)
    -- This space deliberately left blank
end

local registry_listener = {
    ["global"] = registry_handle_global,
    ["global_remove"] = registry_handle_global_remove
}

local function main()
    local display = wau.wl_display.connect(nil)
    local registry = wau.wl_display.get_registry(display)
    wau.wl_registry.add_listener(registry, registry_listener, nil)
    wau.wl_display.roundtrip(display)
    return 0
end

main()    
```

That looks overly similar already. What are some differences?

- The callbacks don't get a data object handed to them
- Well... that's about it, the rest is about conforming to luas language specifics

# "Improvements"

Now there are some improvements we can make with that program to write more lua-style:

## 1. Lua can emulate object-oriented programming

If we got a wayland interface `wl_thing`, then all fields that are accessbile through `wau.wl_thing[key]`, are also accessible by an instance of the interface directly `mything[key]`. 

So instead of doing `wau.wl_display.get_registry(display)`, we could do `display.get_registry(display)`. And if you know a little lua already, that is a case where the `:`-operator comes in handy. It's equivalent to `display:get_registry()`.

```diff
    local display = wau.wl_display.connect(nil)
-   local registry = wau.wl_display.get_registry(display)
+   local registry = display:get_registry()
-   wau.wl_registry.add_listener(registry, registry_listener, nil)
+   registry:add_listener(registry_listener)
-   wau.wl_display.roundtrip(display)
+   display:roundtrip()
```

## 2. Lua is more forgiving

As a scripting language, lua let's you write more freely when doing your wayland work. 

Take for example the `registry_listener`. In C, we need them to be `static const`. But in lua there is no need for them to be declared outside of the function.

```diff
-   registry:add_listener(registry_listener)
+   registry:add_listener {
+       ["global"] = registry_handle_global,
+       ["global_remove"] = registry_handle_global_remove
+   }
```

And even there, we can even inline the functions to which we are here referencing, if we really want to (of course there will be cases where it is more convenient to not do so).

```diff
    registry:add_listener {
-       ["global"] = registry_handle_global,
+       ["global"] = function(registry, name, interface, version)
+           print("interface: " .. interface .. ", version: " .. tostring(version) .. ", name: " .. name)
+       end,
-       ["global_remove"] = registry_handle_global_remove
+       ["global_remove"] = function(registry, name)
+           -- This space deliberately left blank
+       end
    }
```

And of course, having a `main` function was more of an exercise in recreating the C code very precisly. We don't need that in lua, it will just start to execute the script starting from the top. So what we end up after all the refactors is the following:

```lua
local wau = require("wau")

local display = wau.wl_display.connect(nil)
local registry = display:get_registry()

registry:add_listener {
    ["global"] = function(registry, name, interface, version)
        print("interface: " .. interface .. ", version: " .. tostring(version) .. ", name: " .. name)
    end,
    ["global_remove"] = function(registry, name)
        -- This space deliberately left blank
    end
}

display:roundtrip()
```

