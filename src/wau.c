#include <lua.h>

#include "core.h"
#include "misc.h"
#include "events.h"

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

    /* wau functions */
    static const luaL_Reg _functions[] = {
        { "connect",       wau_connect },
        { "require",       wau_require },
        { "connect_event", wau_connect_event },
        { "emit_event",    wau_emit_event },
        { NULL, NULL }
    };
    luaL_setfuncs(L, _functions, 0);

    /* helpers */
    lua_newtable(L);
    lua_pushcfunction(L, allocate_shm);
    lua_setfield(L, -2, "allocate_shm");
    lua_pushcfunction(L, destroy_shm);
    lua_setfield(L, -2, "destroy_shm");
    lua_setfield(L, -2, "helpers");

    return 1;
}
