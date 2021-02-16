#
# 2010/04/20	mini-stdio library
#

PREFIX	= /usr/local/sr/bin/sr-elf-
CC	= $(PREFIX)gcc
LD	= $(PREFIX)ld
AR	= $(PREFIX)ar
OBJCP	= $(PREFIX)objcopy
OBJDUMP	= $(PREFIX)objdump

#FPU = -mfpu-ex

CFLAGS	= -g -Wall -nostartfiles -O2 -I../include -DTXIRQ $(FPU)
#CFLAGS	= -g -Wall -m2 -mrelax -O2
LDFLAGS = -g -Wall -nostdlib $(FPU)
#LDFLAGS = -Wl,-Map,$(TARGET).map -lm
ARFLAGS	= crs

##SRCS1    = ff.c ulib.c mmcbb.c uartdrv.c fprint.c memcpy32.c rcp.c sincos.c fsqrt.c strtok.c
SRCS1    = ulib.c uartdrv.c fprint.c memcpy32.c strtok.c

OBJS1    = $(SRCS1:.c=.o)
DEPS    = $(SRCS1:.c=.dep)

all:	libmc.a fprintf

fprintf:	fprintf.c
	gcc -O2 -Wall fprintf.c -o fprintf

libmc.a:	$(OBJS1)
	$(AR) $(ARFLAGS) libmc.a $(OBJS1)

%.lst:	%.o
	$(OBJDUMP) -D -S -h $< > $@

%.o:	%.c
	$(CC) $(CFLAGS) -c $<

%.dep:	%.c
	$(CPP) $(CFLAGS) -M $< > $@

clean:
	@rm -f *.abs *.o core* a.out *~ \#*\#  *.map *.lst *.dep libmc.a

depend:	$(DEPS)
	cp Makefile Makefile.bak
	sed '/^#----- dependences -----/q' Makefile.bak >Makefile
	echo >>Makefile
	cat *.dep | \
	  sed 's/\/usr\/[^ ]* *//g;/^  \\$$/d' |\
	  grep -v '^ \\$$' >>Makefile
	rm -f *.dep
#       $(CPP) $(CFLAGS) -M $(SRCS) | \

#----- dependences -----

fprint.o: fprint.c ../include/stdio.h \
 ../include/types.h \
 ../include/time.h ../include/ulib.h ../include/uartdrv.h
memcpy32.o: memcpy32.c ../include/stdio.h \
 ../include/types.h \
 ../include/ulib.h ../include/uartdrv.h
strtok.o: strtok.c \
 
uartdrv.o: uartdrv.c ../include/stdio.h \
 ../include/types.h \
 ../include/ulib.h ../include/uartdrv.h
ulib.o: ulib.c ../include/stdio.h \
 ../include/types.h \
 ../include/ulib.h ../include/uartdrv.h ../include/time.h
