# wau overview

To make best use of these bindings, you need a firm understanding of both wayland and lua. For that I advise you to look into the [wayland book](https://wayland-book.com/) for wayland and to read up on the basics of lua if you haven't already.

## requests

All requests can be found usiung their name at `wau.<interface_name>.<request_name>`. It's also possible to call a request on the object directly using familiar lua syntax: `wau.my_interface.my_request(my_obj, a, b)` becomes `my_obj:my_request(a, b)`. The lua syntax should be prefered for readability.

```lua
-- this
registry = wau.wl_display.get_registry(mydisplay)

-- is the same as that
registry = mydisplay:get_registry()
```

Because requests never return anything by themselves, they will return `self` in here to allow for method chaining (see @{layershell.lua}):

```lua
mywidget:set_anchor(Anchor.RIGHT + Anchor.TOP)
        :set_margin(10, 10, 10, 10)
        :set_size(width, height)
        :add_listener { ["configure"] = wau.zwlr_layer_surface_v1.ack_configure }
```

## events

To connect to events, use the `add_listener` method. I personally prefer to put the event name in the lua string indexing syntax `["event_name"]` but I think in normal protocols that follow the naming conventions for events, that shouldn't be needed.

```lua
my_obj:add_listener { ["event_name"] = my_callback }
```

In here `my_callback` is a function that takes `self` as its first parameter and the parameters described in the protocol following that. Unlike in libwayland, there is no `data` field.

## enumerations

Every enumeration is a table on the interface they belong to. The values can be found on that table. Enumeration tables use camel case and the values use upper case for their respective names analogous to lgi. So the overall format will always be: `wau.<inteface_name>.<EnumName>.<VALUENAME>`.

As an example, we'll take a look at the `format` enum of `wl_shm` ([here](https://wayland.app/protocols/wayland#wl_shm:enum:format) for reference). If you want to access the `argb8888` field, you will do so using `wau.wl_shm.Format.ARGB8888` (the value of that enum is 0 by the way).


