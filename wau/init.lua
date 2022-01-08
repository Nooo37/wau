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

return wau
