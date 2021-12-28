package = "wau"
version = "dev-1"

source = {
   url = "git+https://github.com/Nooo37/wau",
   branch = "master",
}

description = {
   summary = "Basic lua libwayland bindings",
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
      ["wau.raw"] = "wau/raw.lua",
      ["wau.wl_proxy"] = "wau/wl_proxy.lua",
      ["wau.wl_interface"] = "wau/wl_interface.lua",
      ["wau.protocol.wayland"] = "wau/protocol/wayland.lua",
   },
   copy_directories = { "example" }
}

