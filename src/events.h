#ifndef WAU_EVENTS_H
#define WAU_EVENTS_H

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <wayland-client.h>

#define WAU_EVENT_FIELD "wau_events"
#define WAU_DISPATCH_FIELD "wau_dispatch"

int wau_connect_event(lua_State *L);
int wau_emit_event(lua_State *L);

int event_dispatcher(const void * data, void *target, uint32_t opcode,
                    const struct wl_message *message,
                    union wl_argument *args);

int wau_add_dispatcher(lua_State *L);

#endif
