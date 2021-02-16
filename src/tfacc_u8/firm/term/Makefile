#
#

CC		= gcc
LINKER		= $(CC)

CFLAGS		= -g -O2 -Wall

LDFLAGS		= -g -O2 -Wall
LDLIBS		= 

SRCS	= term.c 

all:	term 

term:	term.o
	$(CC) -o $@ $(LDFLAGS) $< $(OBJS)

plt:	plt.o
	$(CC) -o $@ $(LDFLAGS) $< $(OBJS) -lgrp -lm

%.o:	%.c
	$(CC) $(CFLAGS) -c $<

clean:;		rm -f term *.o core a.out *~ \#*\# *.bak ;\

###

depend:	$(SRCS)
	cp Makefile Makefile.bak
	sed "/^#----- dependences -----/q" Makefile.bak >Makefile
	echo >>Makefile
	$(CC) $(CFLAGS) -M $(SRCS) | \
          sed 's/\/usr\/include\/[^ ]* *//g;s/\/usr\/lib\/[^ ]* *//g;/^  \\$$/d' |\
          grep -v '^ \\$$' >>Makefile

#----- dependences -----

term.o: term.c \
  
