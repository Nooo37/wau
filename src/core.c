#include <assert.h>
#include <err.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <wayland-server.h>
#include <wayland-client.h>
#include <wayland-cursor.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "core.h"
#include "events.h"

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
        if (lua_isnil(L, -1))
            types[i] = NULL;
        else
            types[i] = *((void**) lua_topointer(L, -1));
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
    struct wl_interface* result_iface = *res;
    assert(lua_istable(L, 2));
    lua_pushvalue(L, 2);

    lua_setuservalue(L, 1);
    
    lua_getfield(L, 2, "name");
    result_iface->name = luaL_checkstring(L, -1);
    lua_pop(L, 1);
    lua_getfield(L, 2, "version");
    result_iface->version = luaL_checknumber(L, -1);
    lua_pop(L, 1);

    lua_getfield(L, 2, "requests");
    assert(lua_istable(L, -1));
    result_iface->method_count = lua_rawlen(L, -1);
    result_iface->methods = parse_messages(L, -1);
    lua_pop(L, 1);

    lua_getfield(L, 2, "events");
    assert(lua_istable(L, -1));
    result_iface->event_count = lua_rawlen(L, -1);
    result_iface->events = parse_messages(L, -1);
    lua_pop(L, 1);

    return 0;
}

int wau_wl_interface_call(lua_State *L)
{
    struct wl_interface** result = (void*) lua_topointer(L, 1);
    lua_pushlightuserdata(L, *result);
    return 1;
}

int wau_wl_interface_newindex(lua_State *L)
{
    lua_getuservalue(L, 1);
    lua_pushvalue(L, 2); /* key */
    lua_pushvalue(L, 3); /* value */
    lua_settable(L, -3);
    return 0;
}

int wau_wl_interface_index(lua_State *L)
{
    lua_getuservalue(L, 1);
    lua_pushvalue(L, 2); /* key */
    lua_gettable(L, -2);
    return 1;
}

int register_interface(lua_State *L)
{
    static const luaL_Reg _metatable[] = {
        { "__index",        wau_wl_interface_index },
        { "__newindex",     wau_wl_interface_newindex },
        { NULL, NULL }
    };
    luaL_newmetatable(L, WL_INTERFACE_MT);
    luaL_setfuncs(L, _metatable, 0);
    lua_pop(L, 1); // we don't care about the metatable anymore for now

    static const luaL_Reg _methods[] = {
        { "new",            wau_wl_interface_new },
        { "init",           wau_wl_interface_init },
        { "connect_event",  wau_connect_event },
        { NULL, NULL }
    };
    lua_newtable(L);
    luaL_setfuncs(L, _methods, 0);
    /* TOOD: add common methods here */
    return 1;
}

/* display */

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
    struct wl_display** dpy = (void*)lua_topointer(L, 1);
    wl_display_disconnect(*dpy);
    return 0;
}

int wau_wl_display_roundtrip(lua_State* L)
{
    struct wl_display** dpy = (void*)lua_topointer(L, 1);
    int res = wl_display_roundtrip(*dpy);
    lua_pushnumber(L, res);
    return 1;
}

static const luaL_Reg display_requests[] = {
    { "roundtrip",    wau_wl_display_roundtrip },
    { "connect",      wau_wl_display_connect },
    { "disconnect",   wau_wl_display_disconnect },
    { NULL, NULL }
};

int register_display(lua_State *L)
{
    lua_newtable(L);
    luaL_setfuncs(L, display_requests, 0);
    return 1;
}

/* proxy */

int wau_wl_proxy_marshal_constructor_versioned(lua_State *L)
{
    struct wl_proxy** proxy = (void*) lua_topointer(L, 1);
    uint32_t opcode = luaL_checknumber(L, 2);
    struct wl_interface** interface = (void*) lua_topointer(L, 3);
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
            args[i].o = *((void**) lua_topointer(L, idx));
        } else if (lua_islightuserdata(L, idx)) {
            args[i].o = (void*) lua_topointer(L, idx);
        }
    }
    struct wl_proxy* id;
    id = wl_proxy_marshal_array_constructor(proxy, opcode, args, interface);
    return id;
}

int wau_wl_proxy_marshal_constructor(lua_State *L)
{
    struct wl_proxy** proxy = (void*) lua_topointer(L, 1);
    uint32_t opcode = luaL_checknumber(L, 2);
    struct wl_interface** interface = (void*) lua_topointer(L, 3);
    lua_remove(L, 1);
    lua_remove(L, 1);
    lua_remove(L, 1);

    struct wl_proxy* id = helper_marshal_constructor_call(L, *proxy, opcode, 
            *interface);
    if (id == NULL)
        errx(1, "rip %s", strerror(errno));

    struct wl_proxy** result = lua_newuserdata(L, sizeof(void*));
    *result = id;
    wl_proxy_add_dispatcher(*result, event_dispatcher, L, L);
    luaL_getmetatable(L, WL_PROXY_MT);
    lua_setmetatable(L, -2);
    return 1;
}

int wau_wl_proxy_marshal(lua_State *L)
{
    struct wl_proxy** proxy = (void*) lua_topointer(L, 1);
    int opcode = luaL_checknumber(L, 2);
    lua_remove(L, 1);
    lua_remove(L, 1);
    helper_marshal_constructor_call(L, *proxy, opcode, NULL);
    return 0;
}

int wau_wl_proxy_get_id(lua_State *L)
{
    struct wl_proxy** proxy = (void*) lua_topointer(L, 1);
    uint32_t id = wl_proxy_get_id(*proxy);
    lua_pushnumber(L, id);
    return 1;
}

int wau_wl_proxy_set_userdata(lua_State *L)
{
    struct wl_proxy** proxy = (void*) lua_topointer(L, 1);
    void* data = (void*) lua_topointer(L, 2);
    wl_proxy_set_user_data(*proxy, data);
    return 0;
}

int wau_wl_proxy_get_userdata(lua_State *L)
{
    struct wl_proxy** proxy = (void*) lua_topointer(L, 1);
    void* data = wl_proxy_get_user_data(*proxy);
    lua_pushlightuserdata(L, data);
    return 1;
}

int wau_wl_proxy_wrapper_destroy(lua_State *L)
{
    struct wl_proxy** proxy = (void*) lua_topointer(L, 1);
    wl_proxy_wrapper_destroy(*proxy);
    return 0;
}

int wau_wl_proxy_get_class(lua_State *L)
{
    struct wl_proxy** proxy = (void*) lua_topointer(L, 1);
    const char* class = wl_proxy_get_class(*proxy);
    lua_pushstring(L, class);
    return 1;
}

int wau_wl_proxy_get_version(lua_State *L)
{
    struct wl_proxy** proxy = (void*) lua_topointer(L, 1);
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

int wau_wl_proxy_index(lua_State *L)
{
    wau_wl_proxy_get_interface(L);
    lua_pushvalue(L, 2);
    lua_gettable(L, -2);
    if (lua_isnil(L, -1) && lua_isstring(L, 2)) {
        const char* key = luaL_checkstring(L, 2);
        // check if it matches one of the defualt methods
        lua_getmetatable(L, 1);
        lua_getfield(L, -1, key);
        if (!lua_isnil(L, -1)) {
            return 1;
        }
    }
    return 1;
}

int register_proxy(lua_State *L)
{
    static const luaL_Reg _methods[] = {
        /* default methods */
        { "connect_event",  wau_connect_event },
        { "emit_event",     wau_emit_event },
        { "add_dispatcher", wau_add_dispatcher },
        { "set_interface",  wau_wl_proxy_set_interface },
        { "get_interface",  wau_wl_proxy_get_interface },

        /* wl_proxy methods */
        { "marshal",       wau_wl_proxy_marshal },
        { "marshal_constructor", 
            wau_wl_proxy_marshal_constructor },
        { "marshal_constructor_versioned", 
            wau_wl_proxy_marshal_constructor_versioned },
        { "set_userdata",   wau_wl_proxy_set_userdata },
        { "get_userdata",   wau_wl_proxy_get_userdata },
        { "get_version",    wau_wl_proxy_get_version },
        { "get_id",         wau_wl_proxy_get_id },
        { "get_class",      wau_wl_proxy_get_class },
        { "destroy",        wau_wl_proxy_wrapper_destroy },

        /* wl_display methods 
         * Having those functions here is a lazy shortcut for adding
         * that functionality to a auto-generated proxy with wl_display 
         * interface as the current implementation doesn't make any difference
         * between a wl_display interface and any other interface and it would
         * be dumb to write wau.display.roundtrip(display) instead of 
         * display:roundtrip() etc */
        { "roundtrip",      wau_wl_display_roundtrip },
        { "connect",        wau_wl_display_connect },
        { "disconnect",     wau_wl_display_disconnect },

        /* metatable */
        { "__index",        wau_wl_proxy_index },
        { NULL, NULL }
    };
    luaL_newmetatable(L, WL_PROXY_MT);
    luaL_setfuncs(L, _methods, 0);
    return 1;
}

/* HELPERS */

int wau_connect(lua_State *L)
{
    wau_wl_display_connect(L);
    lua_pushvalue(L, 1);
    lua_getfield(L, -1, "wl_display");
    lua_setuservalue(L, -3);
    lua_pop(L, 1);
    return 1;
}

int wau_require(lua_State* L)
{
    int status;
    lua_getglobal(L, "require");
    lua_pushvalue(L, 2);
    status = lua_pcall(L, 1, 1, 0); /* call require */
    if (status)
        errx(1, "Error in wau_require: %s\n", lua_tostring(L, -1));
    lua_pushvalue(L, 1);
    lua_pcall(L, 1, 0, 0); /* call the returned function */
    if (status)
        errx(1, "Error in wau_require: %s\n", lua_tostring(L, -1));
    return 0;
}

