package = "wau"
version = "dev-1"

source = {
   url = "git+https://github.com/Nooo37/wau",
   branch = "master",
}

description = {
   summary = "Rudimentary lua libwayland bindings",
   homepage = "https://github.com/Nooo37/wau",
}

build = {
   type = "make",
   install_variables = {
      INST_PREFIX="$(PREFIX)",
      INST_BINDIR="$(BINDIR)",
      INST_LIBDIR="$(LIBDIR)",
      INST_LUADIR="$(LUADIR)",
      INST_CONFDIR="$(CONFDIR)",
      LUA="$(LUA)",
   },
   copy_directories = { "example" }
}

