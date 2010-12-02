##########################################################################
# User configuration and firmware specific object files	
##########################################################################

# The target, flash and ram of the LPC1xxx microprocessor.
# Use for the target the value: LPC11xx, LPC13xx or LPC17xx
TARGET = LPC13xx
FLASH = 32K
SRAM = 8K

# For USB support the LPC134x reserves 384 bytes from the sram,
# if you don't want to use the USB features, just use 0 here.
SRAM_USB = 384

VPATH = 
OBJS = main.o

##########################################################################
# Project-specific files 
##########################################################################

VPATH += project
OBJS += commands.o

VPATH += project/commands
OBJS += cmd_chibi_addr.o cmd_chibi_tx.o cmd_deepsleep.o cmd_hello.o
OBJS += cmd_i2ceeprom_read.o cmd_i2ceeprom_write.o cmd_lm75b_gettemp.o
OBJS += cmd_sysinfo.o cmd_sd_dir.o cmd_lcd_fill.o cmd_lcd_test.o

##########################################################################
# Optional driver files 
##########################################################################

# PN532 NFC Transceiver
# VPATH += drivers/nfc/pn532
# OBJS += pn532.o

# Chibi Light-Weight Wireless Stack (AT86RF212)
VPATH += drivers/chibi
OBJS += chb.o chb_buf.o chb_drvr.o chb_eeprom.o chb_spi.o

# 4K EEPROM
VPATH += drivers/eeprom drivers/eeprom/mcp24aa
OBJS += eeprom.o mcp24aa.o

# LM75B temperature sensor
VPATH += drivers/sensors/lm75b
OBJS += lm75b.o

# TFT LCD support (ILI9325)
VPATH += drivers/lcd/tft drivers/lcd/tft/hw drivers/lcd/tft/fonts
OBJS += ILI9325.o drawing.o touchscreen.o tscalibration.o
OBJS += consolas9.o consolas11.o consolas16.o

# Bitmap LCD support (ST7565)
VPATH += drivers/lcd drivers/lcd/bitmap/st7565
OBJS += smallfonts.o st7565.o

# ChaN FatFS and SD card support
VPATH += drivers/fatfs
OBJS += ff.o mmc.o

# Motors
VPATH += drivers/motor/stepper
OBJS += stepper.o

# RSA Encryption/Descryption
VPATH += drivers/rsa
OBJS += rsa.o

# DAC
VPATH += drivers/dac/mcp4725
OBJS += mcp4725.o

##########################################################################
# Library files 
##########################################################################

VPATH += core core/adc core/cmd core/cpu core/gpio core/i2c core/pmu
VPATH += core/ssp core/systick core/timer16 core/timer32 core/uart
VPATH += core/usbhid-rom core/libc core/wdt core/usbcdc core/pwm
OBJS += adc.o cpu.o cmd.o gpio.o i2c.o pmu.o ssp.o systick.o timer16.o
OBJS += timer32.o uart.o uart_buf.o usbconfig.o usbhid.o stdio.o string.o
OBJS += wdt.o cdcuser.o usbcore.o usbdesc.o usbhw.o usbuser.o sysinit.o
OBJS += pwm.o

##########################################################################
# GNU GCC compiler prefix and location
##########################################################################

CROSS_COMPILE = arm-none-eabi-
AS = $(CROSS_COMPILE)gcc
CC = $(CROSS_COMPILE)gcc
LD = $(CROSS_COMPILE)gcc
SIZE = $(CROSS_COMPILE)size
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
OUTFILE = firmware
LPCRC = ./lpcrc

##########################################################################
# GNU GCC compiler flags
##########################################################################
ROOT_PATH = .
INCLUDE_PATHS = -I$(ROOT_PATH) -I$(ROOT_PATH)/project

##########################################################################
# Startup files
##########################################################################

LD_PATH = lpc1xxx
LD_SCRIPT = $(LD_PATH)/linkscript.ld
LD_TEMP = $(LD_PATH)/memory.ld

ifeq (LPC11xx,$(TARGET))
  CORTEX_TYPE=m0
else
  CORTEX_TYPE=m3
endif

CPU_TYPE = cortex-$(CORTEX_TYPE)
VPATH += lpc1xxx
OBJS += $(TARGET)_handlers.o LPC1xxx_startup.o

##########################################################################
# Compiler settings, parameters and flags
##########################################################################

CFLAGS  = -c -g -Os $(INCLUDE_PATHS) -Wall -mthumb -ffunction-sections -fdata-sections -fmessage-length=0 -mcpu=$(CPU_TYPE) -DTARGET=$(TARGET) -fno-builtin
ASFLAGS = -c -g -Os $(INCLUDE_PATHS) -Wall -mthumb -ffunction-sections -fdata-sections -fmessage-length=0 -mcpu=$(CPU_TYPE) -D__ASSEMBLY__ -x assembler-with-cpp
LDFLAGS = -nostartfiles -mthumb -Wl,--gc-sections
OCFLAGS = --strip-unneeded

all: firmware

%.o : %.c
	$(CC) $(CFLAGS) -o $@ $<

%.o : %.s
	$(AS) $(ASFLAGS) -o $@ $<

firmware: $(OBJS) $(SYS_OBJS)
	-@echo "MEMORY" > $(LD_TEMP)
	-@echo "{" >> $(LD_TEMP)
	-@echo "  flash(rx): ORIGIN = 0x00000000, LENGTH = $(FLASH)" >> $(LD_TEMP)
	-@echo "  sram(rwx): ORIGIN = 0x10000000+$(SRAM_USB), LENGTH = $(SRAM)-$(SRAM_USB)" >> $(LD_TEMP)
	-@echo "}" >> $(LD_TEMP)
	-@echo "INCLUDE $(LD_SCRIPT)" >> $(LD_TEMP)
	$(LD) $(LDFLAGS) -T $(LD_TEMP) -o $(OUTFILE).elf $(OBJS)
	-@echo ""
	$(SIZE) $(OUTFILE).elf
	-@echo ""
	$(OBJCOPY) $(OCFLAGS) -O binary $(OUTFILE).elf $(OUTFILE).bin
	$(OBJCOPY) $(OCFLAGS) -O ihex $(OUTFILE).elf $(OUTFILE).hex
	$(LPCRC) firmware.bin

clean:
	rm -f $(OBJS) $(LD_TEMP) $(OUTFILE).elf $(OUTFILE).bin $(OUTFILE).hex
