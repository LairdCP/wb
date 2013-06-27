#------------------------------------------------------------------------------
# <copyright file="makefile" company="Atheros">
#    Copyright (c) 2005-2008 Atheros Corporation.  All rights reserved.
# $ATH_LICENSE_HOSTSDK0_C$
#------------------------------------------------------------------------------
#==============================================================================
# Author(s): ="Atheros"
#==============================================================================
-include .config

LDFLAGS +=  $(shell $(PKGCONFIG) --cflags --libs glib-2.0)

CC :=$(ATH_CROSS_COMPILE_TYPE)gcc
APP=wmiconfig

NLLIBNAME = libnl-3.0 libnl-genl-3.0
LIBTCMD_DIR := ../libtcmd

LDFLAGS += -ltcmd $(shell $(PKGCONFIG) --libs $(NLLIBNAME)) -lrt
CFLAGS += $(shell $(PKGCONFIG) --cflags $(NLLIBNAME)) -I$(LIBTCMD_DIR) -L$(LIBTCMD_DIR)
all:
	$(CC) -Wall -DUSER_KEYS -g -I$(KERNEL_SRC)/include -Iinclude wmiconfig.c -o $(APP) $(CFLAGS) $(LDFLAGS)

clean:
	$(RM) $(APP)
