#############################################################
#
# SDC2U driver
#
#############################################################

SDC2U_VERSION = local
SDC2U_SITE = package/sdc-closed-source/externals/sdc2u_fips
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
	$(SDC2U_MAKE_ENV) $(MAKE) -C $(@D) sdcu ccm_modules
endef

define SDC2U_INSTALL_TARGET_CMDS
	$(MAKE) --no-print-directory -C $(LINUX_DIR) kernelrelease ARCH=arm CROSS_COMPILE="$(TARGET_CROSS)" > $(@D)/kernel.release
	$(MAKE) --no-print-directory -C $(LINUX_DIR) kernelversion ARCH=arm CROSS_COMPILE="$(TARGET_CROSS)" > $(@D)/kernel.version
	
	$(INSTALL) -D -m 644 $(@D)/sdc2u.ko \
        $(SDC2U_TARGET_DIR)/lib/modules/`cat $(@D)/kernel.release`/extra/sdc2u.ko

    $(INSTALL) -D -m 755 $(@D)/sdcu $(SDC2U_TARGET_DIR)/usr/bin/sdcu
endef

#define SDC2U_UNINSTALL_TARGET_CMDS
#endef

$(eval $(generic-package))
