#ifndef MISC_H
#define MISC_H

#include <lua.h>

int allocate_shm(lua_State* L);
int destroy_shm(lua_State* L);

#endif
