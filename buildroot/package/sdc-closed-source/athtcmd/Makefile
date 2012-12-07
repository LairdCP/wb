CC = gcc
CFLAGS = -Wall -g

NLLIBNAME = libnl-3.0 libnl-genl-3.0
LIBTCMD_DIR := ../libtcmd
PKGCONFIG = pkg-config

LDLIBS += $(shell $(PKGCONFIG) --libs $(NLLIBNAME)) -lrt -ltcmd -lm 
CFLAGS += $(shell $(PKGCONFIG) --cflags $(NLLIBNAME)) -I$(LIBTCMD_DIR) -L$(LIBTCMD_DIR)

all:
	$(MAKE) athtestcmd
	$(MAKE) psatUtil

athtestcmd: athtestcmd.c athtestcmd.h testcmd.h sinit_common.h sinit_common.c sinit_eep.h
	$(CC) $(CFLAGS) -o $@ $^ $(LDLIBS)

psatUtil: psatUtil.c athtestcmd.h testcmd.h sinit_common.h sinit_common.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDLIBS)

clean:
	rm -f athtestcmd
	rm -f psatUtil
