# Scanner

The `wau-scanner` can be used very similarly to the libwayland `wayland-scanner`.

```sh
lua wau-scanner.lua < my-protocol.xml > my-protocol.lua
```

After that you can require the created protocol through

```
local wau = require("wau")
wau:require("my-protocol")
```

That will make all interfaces as defined in `my-protocol` fields in the `wau` table.

Under the hood, `wau:require` makes use of luas normal `require`. That's why the search path is also the same.

By default, `wau` currently only loads the wayland protocol.

