# SPDX-FileCopyrightText: © 2023 Ryan Carsten Schmidt <https://github.com/ryandesign>
# SPDX-License-Identifier: MIT

C2D := c2d
C2T := c2t
CL65 := cl65

PROG := charsetinspector
LOAD_ADDRESS := C00

all: $(PROG).dsk

aif: $(PROG).aif

dsk: $(PROG).dsk

play: $(PROG).aif
	afplay $^

run: $(PROG).dsk
	./openemulator.applescript $^

$(PROG): $(PROG).as
	applesingle decode -o $@.$$$$ $^ && touch $@.$$$$ && mv $@.$$$$ $@

$(PROG).as: $(PROG).s
	$(CL65) -t apple2 -C apple2-asm.cfg --start-addr 0x$(LOAD_ADDRESS) -u __EXEHDR__ -o $@ $^

$(PROG).aif: $(PROG)
	$(C2T) -bc $^,$(LOAD_ADDRESS) $@

$(PROG).dsk: $(PROG)
	$(C2D) -b $<,$(LOAD_ADDRESS) $@

clean:
	rm -f $(PROG) $(PROG).as $(PROG).aif $(PROG).dsk *.o

.PHONY: all aif dsk play run clean
