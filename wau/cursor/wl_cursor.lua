--- A `wl_cursor` represents a given cursor state (loading, clicking etc) in a given cursor theme.
    -- A `wl_cursor` is accessed through a @{wl_cursor_theme}.
    -- You will access the @{wl_cursor_image}s from the cursor in question through the `image` property.
-- @see xdg_top.lua
-- @classmod wl_cursor
-- @alias M

local ffi = require("cffi")
local raw = require("wau.cursor.raw")

local M = { mt = {} }

--- The number of images available
-- @field int The number of @{wl_cursor_image}s that this object possesses in its `image` field.
M.image_count = nil

--- The images associated with the cursor
-- @field {wl_cursor_image,...} A list of @{wl_cursor_image}s. There are @{image_count} many images in this list.
M.image = nil

--- Name of the cursor
-- @field string The name of the cursor.
M.name = nil

--- Find the frame for a given elapsed time in a cursor animation given time in the cursor animation
-- @int time Elapsed time in ms since the beginning of the animation
-- @treturn int The index of the image in the @{image} field that should be displayed for the given time in the cursor animation
function M:frame(time)
    return raw.wl_cursor_frame(self, time)
end

--- Find the frame for a given elapsed time in a cursor animation as well as the time left until next cursor change.
-- @int time Elapsed time in ms since the beginning of the animation
-- @int duration pointer to uint32_t to store time left for this image or zero if the cursor won't change.
-- @treturn int The index of the image in the @{image} field that should be displayed for the given time in the cursor animation
function  M:frame_and_duration(time, duration)
    return raw.wl_cursor_frame_and_duration(self, time, duration)
end

-- metatable

function M.mt.__index(_, k)
    return M[k]
end

function M.mt.__tostring(self)
    local name = ffi.string(self.name)
    return ("<wl_cursor@%s>"):format(name)
end

ffi.metatype("struct wl_cursor", M.mt)

return M
