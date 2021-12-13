NAME          :=wau.so
.DEFAULT_GOAL := $(NAME)
SRCDIR        :=./src
OBJDIR        :=./obj
CC            :=gcc
LDLIBS        :=$(shell pkg-config --libs --cflags lua5.3 wayland-client) -lrt
CFILES        :=$(wildcard $(SRCDIR)/*.c) $(RESFILE)
OBJFILES      :=$(CFILES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)

.PHONY: clean

$(NAME): $(OBJFILES)
	@$(CC) -o $@ -shared --enable-shared -fpic $^ -Wall $(LDLIBS) -export-dynamic

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p obj
	@$(CC) $< -c -o $@ -fpic -Wall $(LDLIBS)

clean:
	@rm -rf ./obj || true
	@rm -f ./$(.DEFAULT_GOAL) || true

