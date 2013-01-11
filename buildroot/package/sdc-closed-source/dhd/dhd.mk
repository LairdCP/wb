#############################################################
#
# DHD driver
#
#############################################################

DHD_VERSION = HEAD
DHD_SITE = svn://10.1.10.7/dev_linux/sdc40n.5x/trunk
DHD_SITE_METHOD = svn
DHD_DEPENDENCIES = linux
DHD_MAKE_ENV = CC="$(TARGET_CC)" \
               CXX="$(TARGET_CXX)" \
               ARCH="$(KERNEL_ARCH)" \
               CFLAGS="$(TARGET_CFLAGS)" \
               LINUXDIR="$(LINUX_DIR)" \
               CROSS_COMPILE="$(TARGET_CROSS)"

DHD_FIRMWARE_FILENAME = 4329b1-4-220-55-sdio-ag-cdc-roml-reclaim-11n-wme-minccx-extsup-aoe-pktfilter-keepalive.bin
DHD_DEBUG = -debug
DHD_TARGET_DIR = $(O)/sdcbins

define DHD_CONFIGURE_CMDS
endef

define DHD_BUILD_CMDS
	#$(MAKE) -C $(@D) clean
    #make ARCH=arm CROSS_COMPILE=arm-sdc-linux-gnueabi- LINUXDIR=~/dev_linux/wb40n/basic/kernel/ dhd-cdc-sdmmc-cfg80211-gpl
	$(DHD_MAKE_ENV) $(MAKE) -C $(@D)/open-src/src/dhd/linux V=1 dhd-cdc-sdmmc-cfg80211-gpl$(DHD_DEBUG)
    $(MAKE) -C $(@D)/open-src/src/wl/exe CC="$(TARGET_CC)"
endef

define DHD_INSTALL_TARGET_CMDS
	$(MAKE) --no-print-directory -C $(LINUX_DIR) kernelrelease ARCH=arm CROSS_COMPILE="$(TARGET_CROSS)" > $(@D)/kernel.release
	$(MAKE) --no-print-directory -C $(LINUX_DIR) kernelversion ARCH=arm CROSS_COMPILE="$(TARGET_CROSS)" > $(@D)/kernel.version
	$(INSTALL) -D -m 644 $(@D)/open-src/src/dhd/linux/dhd-cdc-sdmmc-cfg80211-gpl$(DHD_DEBUG)-`cat $(@D)/kernel.release`/dhd.ko  \
        $(DHD_TARGET_DIR)/lib/modules/`cat $(@D)/kernel.release`/kernel/extra/net/wireless/dhd.ko
    $(INSTALL) -D -m 644 $(@D)/firmware/4329b1/$(DHD_FIRMWARE_FILENAME) \
        $(DHD_TARGET_DIR)/etc/summit/firmware/$(DHD_FIRMWARE_FILENAME)
    ln -s $(DHD_FIRMWARE_FILENAME) $(DHD_TARGET_DIR)/etc/summit/firmware/fw
    $(INSTALL) -D -m 644 $(@D)/nvram/production.nv $(DHD_TARGET_DIR)/etc/summit/nvram/nv
    $(INSTALL) -D -m 755 $(@D)/open-src/src/wl/exe/wl $(DHD_TARGET_DIR)/usr/bin/wl
endef

#define DHD_UNINSTALL_TARGET_CMDS
#endef

$(eval $(call GENTARGETS))
$(eval $(generic-package))
