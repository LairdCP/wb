include ../../laird_version.mk

export PLATFORM = backports
export PRODUCT = backports

export BULID_TYPE = pkg

include ../common.mk

BR2_DL_DIR ?= ../../archive

all:
	cp latest/laird-backport-$(MSD_VERSION).tar.bz2 $(BR2_DL_DIR)/backports-laird-$(MSD_VERSION).tar.bz2
