# Makefile to build and upload assembler sources for Arduino.
#
# @author Bernhard R. Fischer, 4096R/8E24F29D <bf@abenteuerland.at>
#
# @license This is free software, do what ever you like with it.
#
# @usage Put this file into the directory with your assembler sources. The name
# of the directory will be the name of the final (TARGET) file. All assembler
# sources shall have the extension .S, thus being preprocessed by cpp.
# Assembler include (header) files should not have the extensions .s or .S but
# .inc or .h. Have a look at the macros MCU, USBDEV, and BAUD which probably
# have to be changed according to your Arduino board. Finally run `make`. It
# will assemble everything into an elf binary (TARGET.elf) and an Intel hex
# file (TARGET.hex). This can be uploaded by calling `make upload`. To show the
# final disassembly call `make dump`.
#
# @notes To compile and upload using this Makefile you need the packages
# 'gcc-avr' and 'avrdude' (the upload utility).
#
# To connect to the serial port directly (if you programmed the USART0) you
# need a terminal program, e.g. minicom. Run minicom with the following
# statement and options: `minicom -D /dev/ttyACM0 -o -b 9600 -w`
#
TARGET = $(notdir $(CURDIR))
SOURCES = $(wildcard *.S) $(wildcard *.c) $(wildcard *.i)
OBJECTS = $(patsubst %.S,%.o,$(wildcard *.S)) $(patsubst %.c,%.o,$(wildcard *.c))
MCU = atmega328p
#MCU = atmega16
## settings for Uno
USBDEV = /dev/ttyACM0
BAUD = 115200
# settings for Duemilanove
#USBDEV = /dev/ttyUSB0
#BAUD = 57600

AS	= avr-as
CC = avr-gcc
LD = avr-ld
OBJDUMP = avr-objdump
CPP = avr-cpp
COMPRESSOR = xz

CFLAGS = -g -Wall -mmcu=$(MCU)
CPPLAGS = -g -mmcu=$(MCU)
ASFLAGS = -g -mmcu=$(MCU)
LDFLAGS = -Tdata=0x800100 -nostdlib
#LDFLAGS = -Tbss=0x800100 -Tdata=0x800300
AVRDUDE = avrdude
AVRDUDE_CONF = /etc/avrdude.conf

all: $(TARGET).hex

$(TARGET).elf: $(OBJECTS)
	$(CC)	$(LDFLAGS) $(OBJECTS) -o $@

$(TARGET).hex: $(TARGET).elf
	avr-objcopy -O ihex -R .eeprom $(TARGET).elf $(TARGET).hex

upload: $(TARGET).hex
	$(AVRDUDE) -C $(AVRDUDE_CONF) -p $(MCU) -c arduino -P $(USBDEV) -b $(BAUD) -D -U flash:w:$(TARGET).hex:i

dump: $(TARGET).elf
	$(OBJDUMP) -d $(TARGET).elf

clean:
	rm -f $(TARGET).elf $(TARGET).hex $(OBJECTS) *~

$(TARGET).tar:
	if test -d $(TARGET) ; then rm -rf $(TARGET) ; fi
	mkdir $(TARGET)
	cp $(SOURCES) $(MAKEFILE_LIST) $(TARGET)
	tar cf $(TARGET).tar $(TARGET)

dist: $(TARGET).tar
	$(COMPRESSOR) $(TARGET).tar

minicom:
	minicom -D $(USBDEV) -o -b 9600 -w

.PHONY: clean upload dump dist

