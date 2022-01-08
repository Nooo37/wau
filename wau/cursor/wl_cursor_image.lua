local ffi = require("cffi")
local raw = require("wau.cursor.raw")

local M = { mt = {} }

function M.get_buffer(self)
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
