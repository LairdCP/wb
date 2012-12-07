SDCBINS_PRODUCT = $(shell cat $(TOPDIR)/../product.selected)
SDCBINS_VERSION = svn15835
SDCBINS_SOURCE = sdcbins-$(SDCBINS_PRODUCT)-$(SDCBINS_VERSION).tar.gz
SDCBINS_DEPENDENCIES =

define SDCBINS_INSTALL_TARGET_CMDS
    cd $(TARGET_DIR) && tar zxf $(TOPDIR)/../archive/$(SDCBINS_SOURCE) --strip-components=1
endef

$(eval $(call GENTARGETS))
$(eval $(generic-package))
