#include <lua.h>
#include <err.h>

#include "core.h"
#include "helpers.h"

int wau_connect(lua_State *L)
{
    wau_wl_display_connect(L);
    if (lua_isnil(L, -1))
        return 1;
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
        err(1, "Error in wau_require: %s\n", lua_tostring(L, -1));
    lua_pushvalue(L, 1);
    lua_pcall(L, 1, 0, 0); /* call the returned function */
    if (status)
        err(1, "Error in wau_require: %s\n", lua_tostring(L, -1));
    return 0;
}

int luaopen_wau(lua_State* L) {
    lua_newtable(L);

    /* proxy */
    register_proxy(L);
    lua_setfield(L, -2, "proxy");

    /* interface */
    register_interface(L);
    lua_setfield(L, -2, "interface");

    /* display */
    register_display(L);
    lua_setfield(L, -2, "display");

    /* helpers */
    register_helpers(L);
    lua_setfield(L, -2, "helpers");

    /* wau functions */
    static const luaL_Reg _functions[] = {
        { "connect",       wau_connect },
        { "require",       wau_require },
        { NULL, NULL }
    };
    luaL_setfuncs(L, _functions, 0);

    return 1;
}
