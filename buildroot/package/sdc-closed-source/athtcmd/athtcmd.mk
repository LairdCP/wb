#############################################################
#
# Atheros tcmd utility
#
#############################################################

# source included in buildroot
ATHTCMD_VERSION = local
ATHTCMD_SITE = package/sdc-closed-source/athtcmd
ATHTCMD_SITE_METHOD = local
ATHTCMD_DEPENDENCIES = libtcmd

define ATHTCMD_BUILD_CMDS
    $(MAKE) -C $(@D) CC="$(TARGET_CC)" AR="$(TARGET_AR)" \
            PKGCONFIG=../../host/usr/bin/pkg-config \
            LIBTCMD_DIR=../libtcmd-local
endef

define ATHTCMD_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 755 $(@D)/athtestcmd $(TARGET_DIR)/usr/bin/athtestcmd
	$(INSTALL) -D -m 644 $(@D)/athtcmd_ram.bin $(TARGET_DIR)/lib/firmware/ath6k/AR6003/hw2.1.1/athtcmd_ram.bin
endef

define ATHTCMD_UNINSTALL_TARGET_CMDS
	rm -f $(TARGET_DIR)/usr/bin/athtestcmd
    rm -f $(TARGET_DIR)/lib/firmware/ath6k/AR6003/hw2.1.1/athtcmd_ram.bin
endef

$(eval $(generic-package))