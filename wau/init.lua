local wl_display = require("wau.core.wl_display")

local wau = {
    -- core
    wl_proxy        = require("wau.core.wl_proxy"),
    wl_interface    = require("wau.core.wl_interface"),
    -- cursor
    wl_cursor       = require("wau.cursor.wl_cursor"),
    wl_cursor_image = require("wau.cursor.wl_cursor_image"),
    wl_cursor_theme = require("wau.cursor.wl_cursor_theme"),
}

function wau.require(self, k)
    require(k)(self)
end

wau:require("wau.protocol.wayland")

-- add connection relevant methods on the display class
for k, v in pairs(wl_display) do
    wau.wl_display[k] = v
end

return wau
