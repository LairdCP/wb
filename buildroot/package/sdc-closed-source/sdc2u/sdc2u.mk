#############################################################
#
# SDC2U driver and SDCU app for CCMP_FIPS
#
#############################################################

ifeq ($(BR2_PACKAGE_SDC2U_PULL_FROM_SVN),y)
SDC2U_VERSION = $(BR2_PACKAGE_SDC2U_SVN_VERSION)
SDC2U_SITE = svn://10.1.10.7/sserver/ccmp_fips/trunk
SDC2U_SITE_METHOD = svn
else
SDC2U_VERSION = local
SDC2U_SITE = package/sdc-closed-source/externals/sdc2u_fips
SDC2U_SITE_METHOD = local
endif

SDC2U_DEPENDENCIES = linux openssl


MAKE_ENV = \
        ARCH=arm \
        CROSS_COMPILE=$(TARGET_CROSS) \
        KERNELDIR=$(LINUX_DIR)



define SDC2U_CONFIGURE_CMDS
endef

define SDC2U_BUILD_CMDS
	@echo \ --\> sdcu and sdc2u.ko
	$(MAKE) $(MAKE_ENV) -C $(@D)/sdc2u
	$(MAKE) $(MAKE_ENV) -C $(@D)/sdcu
	@echo \ ---
endef

define SDC2U_INSTALL_TARGET_CMDS
	$(MAKE) --no-print-directory $(MAKE_ENV) -C $(LINUX_DIR) kernelrelease > $(@D)/kernel.release
	$(MAKE) --no-print-directory $(MAKE_ENV) -C $(LINUX_DIR) kernelversion > $(@D)/kernel.version
	
	$(INSTALL) -D -m 644 $(@D)/sdc2u/ath6kl_laird.ko \
        $(TARGET_DIR)/lib/modules/`cat $(@D)/kernel.release`/extra/ath6kl_laird.ko
       
	$(INSTALL) -D -m 644 $(@D)/sdc2u/sdc2u.ko \
        $(TARGET_DIR)/lib/modules/`cat $(@D)/kernel.release`/extra/sdc2u.ko
	
	$(INSTALL) -D -m 755 $(@D)/sdcu/sdcu \
        $(TARGET_DIR)/usr/bin/sdcu
endef

define SDC2U_UNINSTALL_TARGET_CMDS
endef

$(eval $(generic-package))
