#include <assert.h>
#include <err.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <wayland-client.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "core.h"
#include "events.h"

static const luaL_Reg common_methods[] = {
    { "connect_event", wau_connect_event },
    { "emit_event",    wau_emit_event },
    { NULL, NULL }
};

/* interface */

int wau_wl_interface_new(lua_State *L)
{
    /* only to keep the boxed-pointer pattern consistent */
    struct wl_interface** result = lua_newuserdata(L, sizeof(void*));
    *result = malloc(sizeof(struct wl_interface));
    luaL_getmetatable(L, WL_INTERFACE_MT);
    lua_setmetatable(L, -2);
    lua_newtable(L);
    lua_setuservalue(L, -2);
    return 1;
}


const struct wl_interface **parse_types(lua_State *L, int idx)
{
    int len = lua_rawlen(L, idx);
    const struct wl_interface **types = malloc(len * sizeof(struct wl_interface));
    lua_pushvalue(L, idx);
    for (int i = 0; i < len; i++) {
        lua_rawgeti(L, -1, i + 1);
        if (lua_isnil(L, -1) || lua_isnumber(L, -1)) /* using 0 for NULLs */
            types[i] = NULL;
        else
            types[i] = *((void**) luaL_checkudata(L, -1, WL_INTERFACE_MT));
        lua_pop(L, 1);
    }
    lua_pop(L, 1);
    return types;
}

struct wl_message* parse_messages(lua_State *L, int idx)
{
    int len = lua_rawlen(L, idx);
    if (len == 0)
        return NULL;
    struct wl_message *messages = malloc(len * sizeof(struct wl_message));
    lua_pushvalue(L, idx);
    for (int i = 0; i < len; i++) {
        lua_rawgeti(L, -1, i + 1);

        lua_getfield(L, -1, "name");
        messages[i].name = luaL_checkstring(L, -1);
        lua_pop(L, 1);

        lua_getfield(L, -1, "signature");
        messages[i].signature = luaL_checkstring(L, -1);
        lua_pop(L, 1);

        lua_getfield(L, -1, "types");
        messages[i].types = parse_types(L, -1);
        lua_pop(L, 1);

        lua_pop(L, 1);
    }
    return messages;
}

int wau_wl_interface_init(lua_State *L)
{
    struct wl_interface** res = luaL_checkudata(L, 1, WL_INTERFACE_MT);
    assert(lua_istable(L, 2));
    lua_pushvalue(L, 2);
    lua_setuservalue(L, 1);
    
    lua_getfield(L, 2, "name");
    (*res)->name = luaL_checkstring(L, -1);
    lua_pop(L, 1);
    lua_getfield(L, 2, "version");
    (*res)->version = luaL_checknumber(L, -1);
    lua_pop(L, 1);

    lua_getfield(L, 2, "requests");
    assert(lua_istable(L, -1));
    (*res)->method_count = lua_rawlen(L, -1);
    (*res)->methods = parse_messages(L, -1);
    lua_pop(L, 1);

    lua_getfield(L, 2, "events");
    assert(lua_istable(L, -1));
    (*res)->event_count = lua_rawlen(L, -1);
    (*res)->events = parse_messages(L, -1);
    lua_pop(L, 1);

    return 0;
}

static const luaL_Reg interface_methods[] = {
    { "new",  wau_wl_interface_new },
    { "init", wau_wl_interface_init },
    { NULL, NULL }
};

int wau_wl_interface__index(lua_State *L)
{
    lua_getuservalue(L, 1);
    lua_pushvalue(L, 2); /* key */
    lua_gettable(L, -2);
    return 1;
}

int wau_wl_interface__newindex(lua_State *L)
{
    lua_getuservalue(L, 1);
    lua_pushvalue(L, 2); /* key */
    lua_pushvalue(L, 3); /* value */
    lua_settable(L, -3);
    return 0;
}

static const luaL_Reg interface_metatable[] = {
    { "__index",    wau_wl_interface__index },
    { "__newindex", wau_wl_interface__newindex },
    { NULL, NULL }
};

int register_interface(lua_State *L)
{
    luaL_newmetatable(L, WL_INTERFACE_MT);
    luaL_setfuncs(L, interface_metatable, 0);
    lua_pop(L, 1); /* we don't care about the metatable anymore for now */

    lua_newtable(L);
    luaL_setfuncs(L, interface_methods, 0);
    luaL_setfuncs(L, common_methods, 0);
    return 1;
}

/* display */

int wau_wl_display_roundtrip(lua_State* L)
{
    struct wl_display** dpy = luaL_checkudata(L, 1, WL_PROXY_MT);
    int res = wl_display_roundtrip(*dpy);
    lua_pushnumber(L, res);
    return 1;
}

int wau_wl_display_connect(lua_State* L)
{
    const char* name = NULL;
    if (lua_isstring(L, -1))
        name = lua_tostring(L, -1);
    struct wl_display** result = lua_newuserdata(L, sizeof(struct wl_display*));
    *result = wl_display_connect(name);
    if (*result == NULL) {
        lua_pushnil(L);
    } else {
        luaL_getmetatable(L, WL_PROXY_MT);
        lua_setmetatable(L, -2);
    }
    return 1;
}

int wau_wl_display_disconnect(lua_State* L)
{
    struct wl_display** dpy = luaL_checkudata(L, 1, WL_PROXY_MT);
    wl_display_disconnect(*dpy);
    return 0;
}

static const luaL_Reg display_methods[] = {
    { "roundtrip",  wau_wl_display_roundtrip },
    { "connect",    wau_wl_display_connect },
    { "disconnect", wau_wl_display_disconnect },
    { NULL, NULL }
};

int register_display(lua_State *L)
{
    lua_newtable(L);
    luaL_setfuncs(L, display_methods, 0);
    luaL_setfuncs(L, common_methods, 0);
    return 1;
}

/* proxy */

int wau_wl_proxy_marshal_constructor_versioned(lua_State *L)
{
    struct wl_proxy** proxy = luaL_checkudata(L, 1, WL_PROXY_MT);
    uint32_t opcode = luaL_checknumber(L, 2);
    struct wl_interface** interface = luaL_checkudata(L, 3, WL_INTERFACE_MT);
    uint32_t version = luaL_checknumber(L, 4);
    uint32_t name = luaL_checknumber(L, 5);

	struct wl_proxy* id = wl_proxy_marshal_constructor_versioned(*proxy,
			 opcode, *interface, version, name, (*interface)->name, version, NULL);
    struct wl_proxy** result = lua_newuserdata(L, sizeof(void*));
    *result = id;
    wl_proxy_add_dispatcher(*result, event_dispatcher, L, L);
    luaL_getmetatable(L, WL_PROXY_MT);
    lua_setmetatable(L, -2);
    return 1;
}

struct wl_proxy* helper_marshal_constructor_call(lua_State *L, 
        struct wl_proxy* proxy, uint32_t opcode, struct wl_interface* interface)
{
    int varargs_len = lua_gettop(L);
    union wl_argument args[varargs_len];
    for (int i = 0; i < varargs_len; i++) {
        int idx = i + 1;
        if (lua_isnil(L, idx)) {
            args[i].o = NULL;
            args[i].s = NULL;
        } else if (lua_isnumber(L, idx)) {
            args[i].i = args[i].u = args[i].f = args[i].h 
                = args[i].n = lua_tonumber(L, idx);
        } else if (lua_isstring(L, idx)) {
            args[i].s = lua_tostring(L, idx);
        } else if (lua_isuserdata(L, idx)) {
            args[i].o = *((void**) luaL_checkudata(L, idx, WL_PROXY_MT));
        } else if (lua_islightuserdata(L, idx)) {
            args[i].o = (void*) lua_topointer(L, idx);
        }
    }
    return wl_proxy_marshal_array_constructor(proxy, opcode, args, interface);
}

int wau_wl_proxy_marshal_constructor(lua_State *L)
{
    struct wl_proxy** proxy = luaL_checkudata(L, 1, WL_PROXY_MT);
    uint32_t opcode = luaL_checknumber(L, 2);
    struct wl_interface** interface = luaL_checkudata(L, 3, WL_INTERFACE_MT);
    lua_remove(L, 1);
    lua_remove(L, 1);
    lua_remove(L, 1);

    struct wl_proxy* id = helper_marshal_constructor_call(L, *proxy, opcode, 
            *interface);
    if (id == NULL)
        err(1, "%s", strerror(errno));

    struct wl_proxy** result = lua_newuserdata(L, sizeof(void*));
    *result = id;
    wl_proxy_add_dispatcher(*result, event_dispatcher, L, L);
    luaL_getmetatable(L, WL_PROXY_MT);
    lua_setmetatable(L, -2);
    return 1;
}

int wau_wl_proxy_marshal(lua_State *L)
{
    struct wl_proxy** proxy = luaL_checkudata(L, 1, WL_PROXY_MT);
    int opcode = luaL_checknumber(L, 2);
    lua_remove(L, 1);
    lua_remove(L, 1);
    helper_marshal_constructor_call(L, *proxy, opcode, NULL);
    return 0;
}

int wau_wl_proxy_get_id(lua_State *L)
{
    struct wl_proxy** proxy = luaL_checkudata(L, 1, WL_PROXY_MT);
    uint32_t id = wl_proxy_get_id(*proxy);
    lua_pushnumber(L, id);
    return 1;
}

int wau_wl_proxy_wrapper_destroy(lua_State *L)
{
    struct wl_proxy** proxy = luaL_checkudata(L, 1, WL_PROXY_MT);
    wl_proxy_wrapper_destroy(*proxy);
    return 0;
}

int wau_wl_proxy_get_class(lua_State *L)
{
    struct wl_proxy** proxy = luaL_checkudata(L, 1, WL_PROXY_MT);
    const char* class = wl_proxy_get_class(*proxy);
    lua_pushstring(L, class);
    return 1;
}

int wau_wl_proxy_get_version(lua_State *L)
{
    struct wl_proxy** proxy = luaL_checkudata(L, 1, WL_PROXY_MT);
    uint32_t version = wl_proxy_get_version(*proxy);
    lua_pushnumber(L, version);
    return 1;
}

int wau_wl_proxy_set_interface(lua_State *L)
{
    assert(lua_isuserdata(L, 1));
    assert(lua_gettop(L) == 2);
    lua_setuservalue(L, 1);
    return 0;
}

int wau_wl_proxy_get_interface(lua_State *L)
{
    assert(lua_isuserdata(L, 1));
    lua_getuservalue(L, 1);
    return 1;
}

static const luaL_Reg proxy_methods[] = {
    { "set_interface",  wau_wl_proxy_set_interface },
    { "get_interface",  wau_wl_proxy_get_interface },
    { "get_version",    wau_wl_proxy_get_version },
    { "get_id",         wau_wl_proxy_get_id },
    { "get_class",      wau_wl_proxy_get_class },
    { "destroy",        wau_wl_proxy_wrapper_destroy },
    { "marshal",        wau_wl_proxy_marshal },
    { "marshal_constructor", wau_wl_proxy_marshal_constructor },
    { "marshal_constructor_versioned", 
        wau_wl_proxy_marshal_constructor_versioned },
    { NULL, NULL }
};

int wau_wl_proxy__index(lua_State *L)
{
    wau_wl_proxy_get_interface(L);
    lua_pushvalue(L, 2);
    lua_gettable(L, -2);
    if (lua_isnil(L, -1) && lua_isstring(L, 2)) {
        const char* key = luaL_checkstring(L, 2);
        /* check if it matches one of the defualt methods */
        lua_getmetatable(L, 1);
        lua_getfield(L, -1, key);
        if (!lua_isnil(L, -1)) {
            return 1;
        }
    }
    return 1;
}

int wau_wl_proxy__tostring(lua_State *L)
{
    struct wl_proxy** obj = luaL_checkudata(L, 1, WL_PROXY_MT);
    lua_getuservalue(L, 1);
    lua_getfield(L, -1, "name");
    const char* name = luaL_checkstring(L, -1);
    uint32_t id = wl_proxy_get_id(*obj);
    char buf[256];
    sprintf(buf, "%s@%d", name, id);
    lua_pushstring(L, buf);
    return 1;
}

int wau_wl_proxy__eq(lua_State *L)
{
    struct wl_proxy** fst = luaL_checkudata(L, 1, WL_PROXY_MT);
    struct wl_proxy** sec = luaL_checkudata(L, 2, WL_PROXY_MT);
    uint32_t id_fst = wl_proxy_get_id(*fst);
    uint32_t id_sec = wl_proxy_get_id(*sec);
    lua_pushboolean(L, id_fst == id_sec);
    return 1;
}

static const luaL_Reg proxy_metatable[] = {
    { "__index",    wau_wl_proxy__index },
    { "__tostring", wau_wl_proxy__tostring },
    { "__eq",       wau_wl_proxy__eq },
    { NULL, NULL }
};

int register_proxy(lua_State *L)
{
    luaL_newmetatable(L, WL_PROXY_MT);
    luaL_setfuncs(L, proxy_metatable, 0);
    luaL_setfuncs(L, proxy_methods, 0);
    luaL_setfuncs(L, common_methods, 0);
    /* for roundtrip ability in wl_display */
    luaL_setfuncs(L, display_methods, 0);
    return 1;
}

