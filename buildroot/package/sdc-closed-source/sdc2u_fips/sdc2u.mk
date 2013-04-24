#############################################################
#
# SDC2U driver
#
#############################################################

SDC2U_VERSION = local
SDC2U_SITE = package/sdc-closed-source/externals/sdc2u
SDC2U_SITE_METHOD = local
SDC2U_DEPENDENCIES = linux
SDC2U_MAKE_ENV = CC="$(TARGET_CC)" \
               CXX="$(TARGET_CXX)" \
               ARCH="$(KERNEL_ARCH)" \
               CFLAGS="$(TARGET_CFLAGS)" \
               LINUXDIR="$(LINUX_DIR)" \
               CROSS_COMPILE="$(TARGET_CROSS)"

SDC2U_DEBUG = -debug
SDC2U_TARGET_DIR = $(TARGET_DIR)

define SDC2U_CONFIGURE_CMDS
endef

define SDC2U_BUILD_CMDS
	#$(MAKE) -C $(@D) clean
    #make ARCH=arm CROSS_COMPILE=arm-sdc-linux-gnueabi- LINUXDIR=~/dev_linux/wb40n/basic/kernel/ dhd-cdc-sdmmc-cfg80211-gpl
	$(SDC2U_MAKE_ENV) $(MAKE) -C $(@D)/open-src/src/dhd/linux V=1 dhd-cdc-sdmmc-cfg80211-gpl$(SDC2U_DEBUG)
    $(MAKE) -C $(@D)/open-src/src/wl/exe CC="$(TARGET_CC)"
endef

define SDC2U_INSTALL_TARGET_CMDS
	$(MAKE) --no-print-directory -C $(LINUX_DIR) kernelrelease ARCH=arm CROSS_COMPILE="$(TARGET_CROSS)" > $(@D)/kernel.release
	$(MAKE) --no-print-directory -C $(LINUX_DIR) kernelversion ARCH=arm CROSS_COMPILE="$(TARGET_CROSS)" > $(@D)/kernel.version
	
	$(INSTALL) -D -m 644 $(@D)/sdc2u.ko \
        $(SDC2U_TARGET_DIR)/lib/modules/`cat $(@D)/kernel.release`/extra/drivers/net/wireless/dhd.ko

    $(INSTALL) -D -m 755 $(@D)/src/wl/exe/wl $(SDC2U_TARGET_DIR)/usr/bin/wl
endef

#define SDC2U_UNINSTALL_TARGET_CMDS
#endef

$(eval $(call GENTARGETS))
$(eval $(generic-package))
