.DEFAULT_GOAL := all
.PHONY: all clean

PROTOCOLS := ./protocol/wlr-foreign-toplevel-management-unstable-v1.lua

./protocol/%.lua:
	mkdir -p protocol
	curl "https://gitlab.freedesktop.org/wlroots/wlr-protocols/-/raw/master/unstable/wlr-foreign-toplevel-management-unstable-v1.xml" \
		| lua ../wau-scanner.lua > ./protocol/wlr-foreign-toplevel-management-unstable-v1.lua

all: $(PROTOCOLS)
	@echo "done"

clean:
	rm -r ./protocol

