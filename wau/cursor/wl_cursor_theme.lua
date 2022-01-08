local ffi = require("cffi")
local raw = require("wau.cursor.raw")

local M = { mt = {} }

ffi.cdef [[
struct wl_shm;
]]

function M.load(name, size, shm)
    local shm_cast = ffi.cast("struct wl_shm*", shm)
    return raw.wl_cursor_theme_load(name, size, shm_cast)
end

function M.destroy(self);
    raw.wl_cursor_theme_destroy(self);
end

function M.get_cursor(self, name)
    return raw.wl_cursor_theme_get_cursor(self, name)
end

-- metatable

function M.mt.__index(_, k)
    return M[k]
end

function M.mt.__tostring(_)
    return "<wl_cursor_theme>"
end

function M.mt.__gc(self)
    M.destroy(self)
end

ffi.metatype("struct wl_cursor_theme", M.mt)


return M
