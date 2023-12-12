# Name: Makefile
# Project: USBaspLoader (updater)
# Author: Stephan Bärwolf
# Creation Date: 2012-09-01
# Tabsize: 4
# License: GNU GPL v2 (see License.txt)

SHELL := /bin/bash

include Makefile.inc

set_tmpfile = $(eval TMPFILE := $(shell mktemp))
# CORRECT_FUSES := E:FF, H:C0, L:1F
CORRECT_FUSES := 0x1f 0xc0

all: do_firmware do_updater

flash:	firmware
	@echo "Flashing firmware..."
	$(MAKE) -C firmware flash
fuse:	firmware
	@echo "Setting fuses..."
	$(MAKE) -C firmware fuse
lock:	firmware
	$(MAKE) -C firmware lock
update:	updater
	$(MAKE) -C updater flash

ff:	flash fuse test

loop:	firmware
	@echo
	@while read -p "${RGRN}Press Enter to flash...${CRES}" r; do \
		if ! make ff; then \
			echo; \
			echo "${RRED}Flashing failed!${CRES}"; \
		fi; \
		echo; \
	done

test:
	@echo "Verifying fuses..."
	$(set_tmpfile)
	@$(AVRDUDE) -U lfuse:r:-:h -U hfuse:r:-:h 2>&1 | tee $(TMPFILE) | ${avrdude_color}
	@FUSES=$$(egrep ^0x $(TMPFILE) | xargs); \
	if [ "$$FUSES" = "${CORRECT_FUSES}" ]; then \
		echo "${RGRN}Fuses correct ($$FUSES), probably FLASHED.${CRES}"; \
		echo; \
	else \
		if ! grep error $(TMPFILE) >/dev/null; then \
			read -p "${RRED}Fuses NOT CORRECT ($$FUSES != ${CORRECT_FUSES}), probably NOT FLASHED.${CRES} Flash now? [Y/n]" r; \
			if [ "x$$r" = "xY" ] || [ "x$$r" = "xy" ] || [ "x$$r" = "x" ]; then \
				make ff; \
			fi; \
		fi; \
	fi
	@rm -f $(TMPFILE)

firmware: do_firmware
updater: do_updater

do_firmware:
	$(ECHO) "."
	$(ECHO) "."
	$(ECHO) "======>BUILDING BOOTLOADER FIRMWARE"
	$(ECHO) "."
	$(MAKE) -C firmware all

do_updater: firmware
	$(ECHO) "."
	$(ECHO) "."
	$(ECHO) "======>BUILDING BOOTLOADER UPDATER (EXPERIMENTAL)"
	$(ECHO) "."
	$(MAKE) -C updater all

deepclean: clean
	$(RM) *~
	$(MAKE) -C updater  deepclean
	$(MAKE) -C firmware deepclean

clean:
	$(MAKE) -C updater  clean
	$(MAKE) -C firmware clean
