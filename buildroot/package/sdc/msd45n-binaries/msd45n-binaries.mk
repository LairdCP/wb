MSD45N_BINARIES_SITE = http://boris.corp.lairdtech.com/builds/Linux/msd45n/beta
MSD45N_BINARIES_VERSION = $(call qstrip,$(BR2_MSD45N_BINARIES_VERSION))
MSD45N_BINARIES_COMPANY_PROJECT = $(call qstrip,$(BR2_MSD45N_BINARIES_COMPANY_PROJECT))
MSD45N_BINARIES_SOURCE = msd45n-$(MSD45N_BINARIES_COMPANY_PROJECT)-$(MSD45N_BINARIES_VERSION).tar.bz2
MSD45N_BINARIES_DEPENDENCIES =

define MSD45N_BINARIES_EXTRACT_CMDS
	$(TAR) -C "$(@D)" -xf $(DL_DIR)/$(MSD45N_BINARIES_SOURCE) 
endef

define MSD45N_BINARIES_CONFIGURE_CMDS
	(cd $(@D) && ls -1 && tar xf rootfs.tar)
endef

define MSD45N_BINARIES_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/usr/bin
    $(INSTALL) -D -m 755 $(@D)/usr/bin/sdc_cli $(TARGET_DIR)/usr/bin/sdc_cli
    $(INSTALL) -D -m 755 $(@D)/usr/bin/sdcsupp $(TARGET_DIR)/usr/bin/sdcsupp
    mkdir -p $(TARGET_DIR)/usr/lib
    $(INSTALL) -m 755 $(@D)/usr/lib/libsdc_sdk.so* $(TARGET_DIR)/usr/lib/
endef

define MSD45N_BINARIES_INSTALL_FIPS_BINARIES
    $(INSTALL) -D -m 755 $(@D)/usr/bin/sdcu $(TARGET_DIR)/usr/bin/sdcu
    $(LINUX_MAKE_FLAGS) $(MAKE) --no-print-directory -C $(LINUX_DIR) kernelrelease > $(@D)/kernel.release
    $(INSTALL) -D -m 644 $(@D)/lib/modules/`cat $(@D)/kernel.release`/extra/ath6kl_laird.ko \
                 $(TARGET_DIR)/lib/modules/`cat $(@D)/kernel.release`/extra/ath6kl_laird.ko
    $(INSTALL) -D -m 644 $(@D)/lib/modules/`cat $(@D)/kernel.release`/extra/sdc2u.ko \
                 $(TARGET_DIR)/lib/modules/`cat $(@D)/kernel.release`/extra/sdc2u.ko
    #$(LINUX_MAKE_FLAGS) $(MAKE) -C $(LINUX_DIR) M=$(@D)/lib/modules/*/extra modules_install
endef

ifeq ($(MSD45N_BINARIES_COMPANY_PROJECT),laird_fips)
MSD45N_BINARIES_DEPENDENCIES += linux
MSD45N_BINARIES_POST_INSTALL_TARGET_HOOKS += MSD45N_BINARIES_INSTALL_FIPS_BINARIES
endif

$(eval $(generic-package))
