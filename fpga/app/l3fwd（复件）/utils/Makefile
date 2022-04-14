
PREFIX ?= /usr/local
BINDIR = $(DESTDIR)$(PREFIX)/bin

CC ?= gcc
CFLAGS ?= -O3

CFLAGS += -Wall
CPPFLAGS += -I../modules/mqnic -I ../include

BIN += l3fwd

DEBUG ?= 0
ifeq ($(DEBUG), 0)
	GENDEPFLAGS = -MD -MP -MF .$(@F).d
else
	GENDEPFLAGS = -MD -MP -MF .$(@F).d -D DEBUG
endif

ALL_CFLAGS = $(CFLAGS) $(CPPFLAGS) $(GENDEPFLAGS)

all: $(BIN)

%.o: %.c
	$(CC) $(ALL_CFLAGS) -c -o $@ $<

l3fwd: l3fwd.o reg_block.o
	$(CC) $(ALL_CFLAGS) $(LDFLAGS) $^ -o $@

install:
	install -d $(BINDIR)
	install -m 0755 $(BIN) $(BINDIR)

clean:
	rm -f $(BIN)
	rm -f *.o
	rm -f .*.d

-include $(wildcard .*.d)

.PHONY: all install clean
