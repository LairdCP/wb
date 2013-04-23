SDCBINS_PRODUCT = $(call qstrip,$(BR2_SDC_PLATFORM))
SDCBINS_VERSION = $(call qstrip,$(BR2_SDCBINS_VERSION))
SDCBINS_SOURCE = sdcbins-$(SDCBINS_PRODUCT)-$(SDCBINS_VERSION).tar.gz
SDCBINS_DEPENDENCIES =

define SDCBINS_INSTALL_TARGET_CMDS
    cd $(TARGET_DIR) && tar zxf $(TOPDIR)/../archive/$(SDCBINS_SOURCE) --strip-components=1
endef

$(eval $(generic-package))
