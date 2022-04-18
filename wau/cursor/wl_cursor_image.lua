--- A `wl_cursor_image` represents a single cursor image (for example a single frame in a loading cursor animation).
    -- You can access a cursor image through a `wl_cursor`s image property.
-- @usage
    -- -- if mycursor is a wl_cursor
    -- local cursor_image = mycursor.image[idx]
    -- local buffer = cursor_image:get_buffer()
-- @classmod wl_cursor_image
-- @alias M

local ffi = require("cffi")
local raw = require("wau.cursor.raw")

local M = { mt = {} }

--- Actual width
-- @field int Actual width
M.width = nil

--- Actual height
-- @field int Actual height
M.height = nil

--- Hot spot x (must be inside image)
-- @field int Hot spot x (must be inside image)
M.hotspot_x = nil

--- Hot spot y (must be inside image)
-- @field int Hot spot y (must be inside image)
M.hotspot_y = nil

--- Animation delay to next frame (ms)
-- @field int Animation delay to next frame (ms)
M.delay = nil


--- Get an shm buffer for a cursor image
-- @treturn wl_shm An shm buffer for the cursor image. The user should not destroy the returned buffer.
function M:get_buffer()
    local obj = raw.wl_cursor_image_get_buffer(self);
    return ffi.cast("struct wl_proxy*", obj)
end

-- metatable

function M.mt.__index(_, k)
    return M[k]
end

function M.mt.__tostring(_)
    return "<wl_cursor_image>"
end

ffi.metatype("struct wl_cursor_image", M.mt)

return M
