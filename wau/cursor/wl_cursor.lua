local ffi = require("cffi")
local raw = require("wau.cursor.raw")

local M = { mt = {} }

function M.frame(self, time)
    return raw.wl_cursor_frame(self, time)
end

function  M.fram_and_duration(self, time, duration)
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
