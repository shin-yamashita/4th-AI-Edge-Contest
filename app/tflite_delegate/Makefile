
# for reference model debug print
#  DFLAGS=-DDEBUG
#
# for ultra96v2 board FPGA delegate
#  DFLAGS=-DULTRA96
#

#mach=`uname -m`
#LIBS = /usr/local/lib/python3.6/dist-packages/tflite_runtime/_interpreter_wrapper.cpython-36m-$(mach)-linux-gnu.so
LIBS = ../tensorflow/tensorflow/lite/tools/make/gen/linux_x86_64/lib/libtensorflow-lite.a

ifeq ($(DFLAGS),-DULTRA96)
 LIBS += -lcma
endif

INC = -I../tensorflow/ -I../tensorflow/tensorflow/lite/tools/make/downloads/gemmlowp/\
  -I../tensorflow/tensorflow/lite/tools/make/downloads/flatbuffers/include

all:	libmydelegate.so.1

libmydelegate.so.1:	MyDelegate.o tfacc_u8.o
	g++ -g -Wall $^  -shared $(LIBS) -Wl,-soname,$@ -o $@

# link error check
main:	main.o MyDelegate.o tfacc_u8.o
	g++ -g -Wall $^ $(LIBS) -o $@ -lpython3.6m -ldl

%.o:	%.cc
	g++ -g -Wall $^ $(INC) -fPIC $(DFLAGS) -c -o $@

clean:
	rm -f *.o libmydelegate.so.1 main


