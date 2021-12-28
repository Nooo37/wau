local wau = {
    require = function(self, k) require(k)(self) end,
    wl_proxy = require("wau.wl_proxy"),
    wl_interface = require("wau.wl_interface"),
}

wau:require("wau.protocol.wayland")

return wau
