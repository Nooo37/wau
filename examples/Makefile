.DEFAULT_GOAL := all
.PHONY: all clean

PROTOCOLS := ./protocol/wlr-foreign-toplevel-management-unstable-v1.lua ./protocol/wlr-layer-shell-unstable-v1.lua ./protocol/wlr-screencopy-unstable-v1.lua ./protocol/xdg-shell.lua

protocol:
	mkdir -p protocol
	curl "https://gitlab.freedesktop.org/wlroots/wlr-protocols/-/raw/master/unstable/wlr-foreign-toplevel-management-unstable-v1.xml" \
		| lua ../wau-scanner.lua > ./protocol/wlr-foreign-toplevel-management-unstable-v1.lua
	curl "https://gitlab.freedesktop.org/wlroots/wlr-protocols/-/raw/master/unstable/wlr-layer-shell-unstable-v1.xml" \
		| lua ../wau-scanner.lua > ./protocol/wlr-layer-shell-unstable-v1.lua
	curl "https://gitlab.freedesktop.org/wlroots/wlr-protocols/-/raw/master/unstable/wlr-screencopy-unstable-v1.xml" \
		| lua ../wau-scanner.lua > ./protocol/wlr-screencopy-unstable-v1.lua
	curl "https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/stable/xdg-shell/xdg-shell.xml" \
		| lua ../wau-scanner.lua > ./protocol/xdg-shell.lua

all: protocol
	make -C helpers
	@echo "done"

clean:
	rm -r ./protocol helpers.so

