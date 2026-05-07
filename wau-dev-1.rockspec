package = "wau"
version = "dev-1"

source = {
   url = "git+https://github.com/Nooo37/wau",
   branch = "master",
}

description = {
   summary = "Basic client-side lua libwayland bindings",
   homepage = "https://github.com/Nooo37/wau",
}

dependencies = {
   "xml2lua >= 1.5",
   "cffi-lua >= 0.2.1",
}

build = {
   type = "builtin",
   modules = {
      ["wau"] = "wau/init.lua",
      ["wau.core.raw"] = "wau/core/raw.lua",
      ["wau.core.wl_display"] = "wau/core/wl_display.lua",
      ["wau.core.wl_interface"] = "wau/core/wl_interface.lua",
      ["wau.core.wl_proxy"] = "wau/core/wl_proxy.lua",
      ["wau.cursor.raw"] = "wau/cursor/raw.lua",
      ["wau.cursor.wl_cursor"] = "wau/cursor/wl_cursor.lua",
      ["wau.cursor.wl_cursor_image"] = "wau/cursor/wl_cursor_image.lua",
      ["wau.cursor.wl_cursor_theme"] = "wau/cursor/wl_cursor_theme.lua",
      ["wau.protocol.wayland"] = "wau/protocol/wayland.lua",
   },
   copy_directories = { "examples" }
}

