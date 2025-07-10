PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin
SCRIPT := bytes.bash
TARGET := bytes

.PHONY: install uninstall help

install: $(SCRIPT)
	install -m 0755 $< $(BINDIR)/$(TARGET)

uninstall:
	rm -f $(BINDIR)/$(TARGET)

help:
	@echo "Usage:"
	@echo "  make install [PREFIX=<path>]    Install $(SCRIPT) to $(BINDIR)/$(TARGET) (default PREFIX=$(PREFIX))"
	@echo "  make uninstall [PREFIX=<path>]  Uninstall $(TARGET)"
