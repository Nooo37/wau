NAME          :=wau
.DEFAULT_GOAL :=$(NAME).so
SRCDIR        :=./src
OBJDIR        :=./obj
CC            :=gcc
LDLIBS        :=$(shell pkg-config --libs --cflags lua5.3 wayland-client) -lrt
CFILES        :=$(wildcard $(SRCDIR)/*.c) $(RESFILE)
OBJFILES      :=$(CFILES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)

SCANNER       :=wau-scanner

.PHONY: clean install

$(.DEFAULT_GOAL): $(OBJFILES)
	$(CC) -o $@ -shared --enable-shared -fpic $^ -Wall $(LDLIBS) -export-dynamic

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	mkdir -p obj
	$(CC) $< -c -o $@ -fpic -Wall $(LDLIBS)

clean:
	rm -rf ./obj
	rm -f ./$(.DEFAULT_GOAL) $(SCANNER).out $(SCANNER)

# only meant for luarocks
install: $(.DEFAULT_GOAL) $(SCANNER).lua
	@echo "--- install wau-scanner ---"
	echo -e "$(LUA) $(INST_BINDIR)/$(SCANNER).lua" > $(SCANNER)
	chmod +x wau-scanner
	cp $(SCANNER) $(SCANNER).lua $(INST_BINDIR)
	@echo "--- install wau ---"
	cp $(.DEFAULT_GOAL) $(INST_LIBDIR)

