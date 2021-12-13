#ifndef WAU_MAIN_H
#define WAU_MAIN_H

#include <stdio.h>
#include <wayland-client.h>

#include <lua.h>
#include <lauxlib.h>

#define WL_INTERFACE_MT "wl_interface"
#define WL_PROXY_MT "wl_proxy"

int register_interface(lua_State *L);
int register_proxy(lua_State *L);
int register_display(lua_State *L);

int wau_connect(lua_State *L);
int wau_require(lua_State *L);

#endif
