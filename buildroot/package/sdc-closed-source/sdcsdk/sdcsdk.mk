#############################################################
#
# SDC SDK
#
#############################################################

SDCSDK_VERSION = local
SDCSDK_SITE = package/sdc-closed-source/externals/sdk
SDCSDK_SITE_METHOD = local
SDCSDK_DEPENDENCIES = libnl
SDCSDK_INSTALL_STAGING = YES
SDCSDK_MAKE_ENV = CFLAGS="$(TARGET_CFLAGS) -I$(STAGING_DIR)/usr/include/libnl3" \
                  LIBS="-l nl-3 -lnl-genl-3"
SDCSDK_TARGET_DIR = $(O)/sdcbins

define SDCSDK_CONFIGURE_CMDS
    patch -d $(@D) < package/sdc-closed-source/sdcsdk/makefile.patch
endef

define SDCSDK_BUILD_CMDS
    $(MAKE) -C $(@D) clean
	$(SDCSDK_MAKE_ENV) $(MAKE) -j 1 -C $(@D) ARCH=$(KERNEL_ARCH) CROSS_COMPILE="$(TARGET_CROSS)"
endef

define SDCSDK_INSTALL_STAGING_CMDS
    rm -f $(STAGING_DIR)/usr/lib/libsdc_sdk.so*
	$(INSTALL) -D -m 0755 $(@D)/libsdc_sdk.so.1.0 $(STAGING_DIR)/usr/lib/
    cd  $(STAGING_DIR)/usr/lib/ && ln -s libsdc_sdk.so.1.0 libsdc_sdk.so.1
    cd  $(STAGING_DIR)/usr/lib/ && ln -s libsdc_sdk.so.1 libsdc_sdk.so
	$(INSTALL) -D -m 0755 $(@D)/include/sdc_sdk.h \
                          $(@D)/include/sdc_events.h \
                          $(@D)/include/config_strings.h \
                          $(STAGING_DIR)/usr/include/
endef

define SDCSDK_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/libsdc_sdk.so.1.0 $(SDCSDK_TARGET_DIR)/usr/lib/libsdc_sdk.so.1.0
endef

define SDCSDK_UNINSTALL_TARGET_CMDS
	rm -f $(SDCSDK_TARGET_DIR)/usr/lib/libsdc_sdk.so.1.0
endef

$(eval $(call GENTARGETS))
$(eval $(generic-package))