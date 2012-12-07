SDCBINS_PRODUCT = $(shell cat $(TOPDIR)/../product.selected)
SDCBINS_VERSION = 3dec2012
SDCBINS_SITE = http://www.thrysoee.dk/editline
SDCBINS_SOURCE = sdc-binaries-$(SDCBINS_PRODUCT)-$(SDCBINS_VERSION).tar.gz
SDCBINS_DEPENDENCIES =

define SDCBINS_INSTALL_TARGET_CMDS
    cd $(TARGET_DIR) && tar zxf $(TOPDIR)/../archive/$(SDCBINS_SOURCE)
endef

$(eval $(generic-package))
