#
# 2007/04/09  sr_test compile for sr cpu
# 2010/04/26	srmon with fat16
#

vpath	%.s	./startup

PREFIX	= /usr/local/sr/bin/sr-elf-
CC	= $(PREFIX)gcc
LD	= $(PREFIX)ld
OBJCP	= $(PREFIX)objcopy
OBJDUMP	= $(PREFIX)objdump

#FPU = -mfpu-ex

#CFLAGS	= -g -Wall -mfpu-ex -std=c99 -nostartfiles -O2 -I../include -I../lib
CFLAGS	= -g -Wall $(FPU) -std=c99 -nostartfiles -O2 -I../include -I../lib
#CFLAGS	= -g -Wall -m2 -mrelax -O2

LDFLAGS =  -g -Wall -nostdlib 
#LDFLAGS = -Wl,-Map,$(TARGET).map -lm

LDSCRIPT	= startup/lnkscr.x
STARTUPFILE	= startup/crt0.s

all:	srmon.abs srmon.mot

SRCS1    = srmon.c
OBJS1    = $(SRCS1:.c=.o)
# conv_test.o
OBJSA   = vector.o crt0.o
DEPS    = $(SRCS1:.c=.dep)

srmon.abs:	$(OBJSA) $(OBJS1)
	$(CC) -o $@ $(LDFLAGS) -Wl,-Map,$(@:.abs=.map) -T$(LDSCRIPT)  -L../lib $(OBJSA) $(OBJS1) -lmc -lc -lgcc

list:	srmon.lst

%.lst:	%.abs
	$(OBJDUMP) -D -S -h -p $< > $@

%.o:	%.c
	$(CC) $(CFLAGS) -c $<

%.o:	%.cc
	$(CXX) $(CFLAGS) -c $<

%.o:	%.s
	$(CC) $(CFLAGS) -c $<

%.dep:	%.c
	$(CPP) $(CFLAGS) -MM $< > $@

%.mot:	%.abs
	$(OBJCP) -O srec --srec-forceS3 -S -R .stack $< $@

install:	srmon.mot
	scp srmon.mot u96usb:tfacc_u8/

clean:
	@rm -f srmon.abs *.o core* a.out *~ \#*\# *.coe *.mif  prog.mem *.map *.lst

srmon.mem:	srmon.mot
	../tool/genrom16k -mif32 srmon.mot -o dpram64kB -s 64
	../tool/genrom16k -coe32 srmon.mot -o dpram64kB -s 64
	../tool/genrom16k -mem srmon.mot -o srmon -s 64


depend:	$(DEPS)
	cp Makefile Makefile.bak
	sed '/^#----- dependences -----/q' Makefile.bak >Makefile
	echo >>Makefile
	cat *.dep >> Makefile
	rm -f *.dep

#----- dependences -----

srmon.o: srmon.c ../include/stdio.h ../include/types.h ../include/ulib.h \
 ../include/uartdrv.h
