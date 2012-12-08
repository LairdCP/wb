#############################################################
#
# SDC Supplicant
#
#############################################################

SDCSUPP_VERSION = local
SDCSUPP_SITE = package/sdc-closed-source/externals/wpa_supplicant
SDCSUPP_SITE_METHOD = local
SDCSUPP_DEPENDENCIES = libnl sdcsdk
SDCSUPP_TARGET_DIR = $(O)/sdcbins

define SDCSUPP_CONFIGURE_CMDS
    patch -d $(@D)/wpa_supplicant < package/sdc-closed-source/sdcsupp/config_openssl.patch
    patch -d $(@D)/wpa_supplicant < package/sdc-closed-source/sdcsupp/config_openssl_remove_wext.patch
    patch -d $(@D)/src/drivers < package/sdc-closed-source/sdcsupp/undef_sdc_in_driver_nl80211.patch
endef

define SDCSUPP_BUILD_CMDS
    cp $(@D)/wpa_supplicant/config_openssl $(@D)/wpa_supplicant/.config
    $(MAKE) -C $(@D)/wpa_supplicant clean
    CFLAGS="-I$(STAGING_DIR)/usr/include/libnl3 $(TARGET_CFLAGS) -MMD -Wall -g" \
        $(MAKE) -C $(@D)/wpa_supplicant V=1 NEED_TLS_LIBDL=1 \
            CROSS_COMPILE="$(TARGET_CROSS)" wpa_supplicant
    $(TARGET_CROSS)objcopy -S $(@D)/wpa_supplicant/wpa_supplicant $(@D)/wpa_supplicant/sdcsupp
    #(cd $(@D)/wpa_supplicant && CROSS_COMPILE=arm-sdc-linux-gnueabi ./sdc-build-linux.sh 4 1 2 3 1)
endef

define SDCSUPP_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 755 $(@D)/wpa_supplicant/sdcsupp $(SDCSUPP_TARGET_DIR)/usr/bin/sdcsupp
endef

define SDCSUPP_UNINSTALL_TARGET_CMDS
	rm -f $(SDCSUPP_TARGET_DIR)/usr/bin/sdcsupp
endef

$(eval $(call GENTARGETS))
$(eval $(generic-package))
