
# Set LRD_BUILDROOT_OUTPUT to point to the outout directory of buildroot.
# Buildroot must be fully built.
LRD_BUILDROOT_OUTPUT = ../../buildroot/output

CC = arm-sdc-linux-gnueabi-gcc
IDIR = -I$(LRD_BUILDROOT_OUTPUT)/host/usr/arm-buildroot-linux-gnueabi/sysroot/usr/include
LDIR = -L$(LRD_BUILDROOT_OUTPUT)//host/usr/arm-buildroot-linux-gnueabi/sysroot/usr/lib

CFLAGS = -c -Wall $(IDIR) -ggdb

_EXE  = eventmon
_OBJS = eventmon.o 
_LIBS = -lsdc_sdk -llrd_platspec -lpthread -lnl-3 -lnl-genl-3

%.o: %.c
	$(CC) $(CFLAGS) $^ -o $@

    
$(_EXE): $(_OBJS)
	$(CC) -o $(_EXE) $(_OBJS) $(LDIR) $(_LIBS) 

    
clean:
	rm -f $(_OBJS) $(_EXE)

.PHONY: clean

