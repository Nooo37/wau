--- A `wl_display` consist of two parts:
    -- The `wl_display` as defined in the wayland.xml protocol
    -- and the one that handles the connection to the wayland compositor.
    -- In here only the connection handling aspect is documented.
-- @classmod wl_display
-- @alias M

local ffi = require("cffi")

local raw = require("wau.core.raw")

local M = {}

--- Work off all staging events through their respective event listeners
-- @treturn wl_display Self
function M:roundtrip()
    local p = ffi.cast("struct wl_display*", self)
    raw.wl_display_roundtrip(p)
    return self
end

function M:flush()
    local display = ffi.cast("struct wl_proxy*", self)
    raw.wl_display_flush(display)
    return self
end

--- Disconnect from the wayland compositor
-- @treturn wl_display self
function M:disconnect()
    local display = ffi.cast("struct wl_display*", self)
    raw.wl_display_disconnect(display)
    return self
end

--- Connect to an existing wayland compositor
-- @string? name
    -- If `nil` then `XDG_RUNTIME_DIR` and `WAYLAND_DISPLAY` will be concatenated
-- @see list_globals.lua
-- @usage
    -- local display = wau.wl_display.connect()
-- @treturn ?wl_display A @{wl_display} on success and `nil` on error
function M.connect(name)
    local temp = raw.wl_display_connect(name)
    local display = ffi.cast("struct wl_proxy*", temp)
    if display == ffi.nullptr then
        return nil
    else
        return display
    end
end

-- since a lua wl_display will be a proxy first, it doesn't make sense
-- to define a metatype for `struct wl_display` here

return M
