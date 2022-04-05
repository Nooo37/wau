# wau - lua libwayland bindings

## Installation

You can of course just clone the repo to where you need it. The easiest way to install it globally on your computer is through luarocks:

```sh
sudo luarocks install --server=https://luarocks.org/dev wau
```

## Getting started

Read up on the documentation in `docs/` especially if you come from C libwayland programming.

I also think the examples are great to get a grasp of wau. To run the examples, you need to run `make` in the example directory. I advise you to check out `list_globals.lua` and `foreign_toplevel_manager.lua`. If you are using lua 5.3 and you got lua lgi installed, you can also try running the other two examples. They require the built of `helpers.so` to be successful though. They are also inherintly more complex as they handle some graphics to show in the windows they create.


> wau wau     ~ 🐕

