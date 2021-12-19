#include <assert.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <stdbool.h>
#include <string.h>
#include <wayland-client.h>

#include "events.h"
#include "core.h"

/* Functions that get connected to signals are stored in the LUA_REGISTRY
 * in an appropiate place */

int get_dispatcher_list(lua_State *L, lua_Integer id)
{
    /* get the dispatcher field */
    lua_getfield(L, LUA_REGISTRYINDEX, WAU_DISPATCH_FIELD);
    if (lua_isnil(L, -1)) {
        lua_pop(L, 1);
        lua_newtable(L);
        lua_setfield(L, LUA_REGISTRYINDEX, WAU_DISPATCH_FIELD);
        lua_getfield(L, LUA_REGISTRYINDEX, WAU_DISPATCH_FIELD);
    }
    /* get the field of the specific object */
    lua_rawgeti(L, -1, id);
    if (lua_isnil(L, -1)) {
        lua_pop(L, 1);
        lua_newtable(L);
        lua_rawseti(L, -2, id);
        lua_rawgeti(L, -1, id);
    }
    lua_remove(L, -2);
    return 1;
}

void wau_call_dispatcher(lua_State *L)
{
    int args_end_index = lua_gettop(L);
    int args_count = args_end_index - 1;
    void** obj = lua_touserdata(L, 1);
    lua_Integer id = (lua_Integer) *obj;
    get_dispatcher_list(L, id);
    int len;
#if !defined LUA_VERSION_NUM || LUA_VERSION_NUM==501
    len = lua_objlen(L, -1);
#else
    len = lua_rawlen(L, -1);
#endif
    for (int i = 1; i <= len; i++) {
        lua_rawgeti(L, -1, i);
        /* arguments will be used by the function call -> push copies */
        for (int i = 1; i < args_count + 1; i++) {
            lua_pushvalue(L, i + 1);
        }
        int res = lua_pcall(L, args_count, 0, 0);
        if (res) {
            lua_pop(L, 1);
        }
        lua_settop(L, args_end_index);
    }
}

int wau_add_dispatcher(lua_State *L)
{
    void** obj = lua_touserdata(L, 1);
    assert(lua_isfunction(L, 2));
    lua_Integer id = (lua_Integer) *obj;
    get_dispatcher_list(L, id);
    lua_pushvalue(L, 2);
    luaL_ref(L, -2);
    return 0;
}

int get_event_list(lua_State *L, lua_Integer id, const char* event_name)
{
    /* Just getting the relevant list of functions here
     * if any given field doesn't exist, create it as it
     * might be needed when this function is called from
     * the connect_event method.
     * REGISTRY -> Object specific table -> event specific list
     * */

    /* get the event field */
    lua_getfield(L, LUA_REGISTRYINDEX, WAU_EVENT_FIELD);
    if (lua_isnil(L, -1)) {
        lua_pop(L, 1);
        lua_newtable(L);
        lua_setfield(L, LUA_REGISTRYINDEX, WAU_EVENT_FIELD);
        lua_getfield(L, LUA_REGISTRYINDEX, WAU_EVENT_FIELD);
    }
    /* get the field of the specific object */
    lua_rawgeti(L, -1, id);
    if (lua_isnil(L, -1)) {
        lua_pop(L, 1);
        lua_newtable(L);
        lua_rawseti(L, -2, id);
        lua_rawgeti(L, -1, id);
    }
    /* get the field of the specific event */
    lua_getfield(L, -1, event_name);
    if (lua_isnil(L, -1)) {
        lua_pop(L, 1);
        lua_newtable(L);
        lua_setfield(L, -2, event_name);
        lua_getfield(L, -1, event_name);
    }
    /* the first two tables don't really matter for us */
    lua_remove(L, -2);
    lua_remove(L, -2);
    return 1;
}

int wau_connect_event(lua_State *L)
{
    /*
     * 1: self/object
     * 2: event name
     * 3: lua function
     * */

    /* check all arguments */
    void** obj = lua_touserdata(L, 1);
    lua_Integer id = (lua_Integer) *obj;
    const char* event_name = luaL_checkstring(L, 2);
    if (!lua_isfunction(L, 3))
        return 0;
    /* get the relevant list on top of the stack */
    get_event_list(L, id, event_name);
    /* append the function to the field */
    lua_pushvalue(L, 3);
    luaL_ref(L, -2);
    /* cleanup */
    lua_pop(L, 3);
    return 0;
}

int wau_emit_event(lua_State *L)
{
    /*
     * 1: self/object
     * 2: event name
     * ...: possible callback arguments
     * */

    int args_end_index = lua_gettop(L);
    int args_count = args_end_index - 2;
    void** obj = lua_touserdata(L, 1);
    lua_Integer id = (lua_Integer) *obj;
    const char *event_name = luaL_checkstring(L, 2);
    /* get the relevant list on top of the stack */
    get_event_list(L, id, event_name);
    /* iterate over all entries and try to call them */
    int len;
#if !defined LUA_VERSION_NUM || LUA_VERSION_NUM==501
    len = lua_objlen(L, -1);
#else
    len = lua_rawlen(L, -1);
#endif
    for (int i = 1; i <= len; i++) {
        get_event_list(L, id, event_name);
        lua_rawgeti(L, -1, i);
        /* arguments will be used by the functioncall -> push copies */
        for (int i = 1; i < args_count + 1; i++) {
            lua_pushvalue(L, i + 2);
        }
        int res = lua_pcall(L, args_count, 0, 0);
        if (res) {
            printf("Error: %s\n", luaL_checkstring(L, -1));
            lua_pop(L, 1);
        }
        lua_settop(L, args_end_index);
    }
    return 0;
}

int event_dispatcher(const void * data, void *target, uint32_t opcode,
                    const struct wl_message *message,
                    union wl_argument *args)
{
    lua_State* L = (lua_State*) data;
    lua_settop(L, 0);
    lua_pushlightuserdata(L, &target);
    lua_pushstring(L, message->name);

    bool next_can_be_nil = false;
    for (int i = 0; i < strlen(message->signature); i++){
        /* TODO support arrays */
        switch (message->signature[i]) {
            case 'i': lua_pushnumber(L, args[i].i); break;
            case 'u': lua_pushnumber(L, args[i].u); break;
            case 'f': lua_pushnumber(L, args[i].f); break;
            case 'h': lua_pushnumber(L, args[i].h); break;
            case 'n': lua_pushnumber(L, args[i].n); break;
            case 's': 
                if (next_can_be_nil && args[i].s == NULL)
                    lua_pushnil(L);
                else
                   lua_pushstring(L, args[i].s);
                next_can_be_nil = false;
                break;
            case 'o':
                if (next_can_be_nil && args[i].o == NULL)
                    lua_pushnil(L);
                else {
                    printf("huch %s\n", message->name);
                    //if (message->types[i] != NULL)
                    //    printf("emit object of type %s\n", message->types[i]->name);
                    void** udata = lua_newuserdata(L, sizeof(void*));
                    *udata = args[i].o;
                    luaL_setmetatable(L, WL_PROXY_MT);
                }
                next_can_be_nil = false;
                break;
            case '?':
                next_can_be_nil = true;
                break;
        }
    }

    /* call dispatchers and event connections
     * those functions should be overall stack-neutral */
    wau_emit_event(L);
    wau_call_dispatcher(L);
    return 0;
}

