local ffi = require("cffi")

local raw = require("wau.core.raw")

local M = {}

function M.roundtrip(self)
    local p = ffi.cast("struct wl_display*", self)
    raw.wl_display_roundtrip(p)
    return self
end

function M.flush(self)
    local display = ffi.cast("struct wl_proxy*", self)
    raw.wl_display_flush(display)
    return self
end

function M.connect(self)
    local temp = raw.wl_display_connect(self)
    local display = ffi.cast("struct wl_proxy*", temp)
    return display == ffi.nullptr and nil or display
end

function M.disconnect(self)
    local display = ffi.cast("struct wl_display*", self)
    raw.wl_display_disconnect(display)
    return self
end

-- since a lua wl_display will be a proxy first, it doesn't make sense
-- to define a metatype for `struct wl_display` here

return M
