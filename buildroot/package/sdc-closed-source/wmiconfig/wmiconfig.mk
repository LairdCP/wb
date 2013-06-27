#############################################################
#
# Atheros tcmd utility
#
#############################################################

# source included in buildroot
WMICONFIG_VERSION = local
WMICONFIG_SITE = package/sdc-closed-source/wmiconfig
WMICONFIG_SITE_METHOD = local
WMICONFIG_DEPENDENCIES = libtcmd

define WMICONFIG_BUILD_CMDS
    $(MAKE) -C $(@D) CC="$(TARGET_CC)" AR="$(TARGET_AR)" \
            PKGCONFIG=../../host/usr/bin/pkg-config \
            LIBTCMD_DIR=../libtcmd-local
endef

define WMICONFIG_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 755 $(@D)/wmiconfig $(TARGET_DIR)/usr/bin/wmiconfig
endef

define WMICONFIG_UNINSTALL_TARGET_CMDS
	rm -f $(TARGET_DIR)/usr/bin/wmiconfig
endef

$(eval $(generic-package))
