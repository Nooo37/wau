.DEFAULT_GOAL := all
.PHONY: all clean

PROTOCOLS := ./protocol/wlr-layer-shell-unstable-v1.lua ./protocol/wlr-screencopy-unstable-v1.lua ./protocol/xdg-shell.lua ./protocol/wayland.lua

./protocol/%.lua:
	mkdir -p protocol
	curl "https://gitlab.freedesktop.org/wlroots/wlr-protocols/-/raw/master/unstable/wlr-layer-shell-unstable-v1.xml" \
		| lua ../wau-scanner.lua > ./protocol/wlr-layer-shell-unstable-v1.lua
	curl "https://gitlab.freedesktop.org/wlroots/wlr-protocols/-/raw/master/unstable/wlr-screencopy-unstable-v1.xml" \
		| lua ../wau-scanner.lua > ./protocol/wlr-screencopy-unstable-v1.lua
	curl "https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/stable/xdg-shell/xdg-shell.xml" \
		| lua ../wau-scanner.lua > ./protocol/xdg-shell.lua
	curl "https://gitlab.freedesktop.org/wayland/wayland/-/raw/main/protocol/wayland.xml" \
		| lua ../wau-scanner.lua > ./protocol/wayland.lua

wau.so: ../wau.so
	cp ../wau.so .

all: wau.so $(PROTOCOLS)
	@echo "done"

clean:
	rm -r ./protocol
