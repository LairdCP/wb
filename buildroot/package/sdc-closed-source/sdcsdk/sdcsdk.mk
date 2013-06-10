#############################################################
#
# SDC SDK
#
#############################################################

SDCSDK_VERSION = 19616
SDCSDK_SITE = svn://10.1.10.7/dev_linux/sdk/trunk
SDCSDK_SITE_METHOD = svn
SDCSDK_DEPENDENCIES = libnl host-pkgconf
SDCSDK_INSTALL_STAGING = YES
SDCSDK_MAKE_ENV = CFLAGS="$(TARGET_CFLAGS)" PKG_CONFIG="$(HOST_DIR)/usr/bin/pkg-config"
SDCSDK_TARGET_DIR = $(TARGET_DIR)

SDCSDK_PLATFORM := $(call qstrip,$(BR2_SDC_PLATFORM))
ifeq ($(SDCSDK_PLATFORM),wb45n)
    SDCSDK_RADIO_FLAGS := CONFIG_SDC_RADIO_QCA45N=y
else ifeq ($(SDCSDK_PLATFORM),wb40n)
    SDCSDK_RADIO_FLAGS := CONFIG_SDC_RADIO_BCM40N=y
else
    $(error "ERROR: Expected BR2_SDC_PLATFORM to be wb45n or wb40n.")
endif

define SDCSDK_BUILD_CMDS
    $(MAKE) -C $(@D) clean
	$(SDCSDK_MAKE_ENV) $(MAKE) -j 1 -C $(@D) ARCH=$(KERNEL_ARCH) \
        CROSS_COMPILE="$(TARGET_CROSS)" $(SDCSDK_RADIO_FLAGS)
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

$(eval $(generic-package))
