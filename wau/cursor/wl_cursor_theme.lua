--- A `wl_cursor_theme` is a set of @{wl_cursor}s with a unified appearance.
    -- Thus the normal workflow is to load a cursor theme through @{load}
    -- and to then retrieve the needed @{wl_cursor} through @{get_cursor}.
    -- Once you got a `wl_cursor`, you can access its @{wl_cursor_image}s through
    -- the @{wl_cursor.image} property. Then you can get the images buffer
    -- with the @{wl_cursor_image.get_buffer} method. After that you can attach the
    -- buffer to a surface and run `set_cursor` on the surface whose cursor you want
    -- to set.
    --
    -- You can look up on how it can be done in the @{xdg_top.lua} example.
-- @see xdg_top.lua
-- @usage
    -- local ctheme = wau.wl_cursor_theme.load(nil, 24, shm)
    -- local cursor = ctheme:get_cursor("cross")
-- @classmod wl_cursor_theme
-- @alias M

local ffi = require("cffi")
local raw = require("wau.cursor.raw")

local M = { mt = {} }

ffi.cdef [[
struct wl_shm;
]]

--- Load a cursor theme to memory shared with the compositor
-- @string? name The name of the cursor theme to load. If `nil`, the default theme will be loaded.
-- @int size Desired size of the cursor images.
-- @tparam wl_shm shm The compositor's shm interface.
-- @usage
    -- -- issue with ldoc: This is a static function / constructor and not a method
    -- local ctheme = wau.wl_cursor_theme.load(name, size, shm)
-- @todo This is a method in ldoc even though it should just be a static function
-- @treturn wl_cursor_theme An object representing the theme that
function M.load(name, size, shm)
    local shm_cast = ffi.cast("struct wl_shm*", shm)
    return raw.wl_cursor_theme_load(name, size, shm_cast)
end

--- Destroys a cursor theme object
function M:destroy();
    raw.wl_cursor_theme_destroy(self);
end

--- Get the cursor for a given name from a cursor theme
-- @string name Name of the desired cursor
-- @treturn wl_cursor The theme's cursor of the given name or %NULL if there is no such cursor
function M:get_cursor(name)
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
