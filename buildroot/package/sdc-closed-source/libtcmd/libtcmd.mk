#############################################################
#
# atheros tcmd library
#
#############################################################

# source included in buildroot
LIBTCMD_VERSION = local
LIBTCMD_SITE = package/sdc-closed-source/libtcmd
LIBTCMD_SITE_METHOD = local
LIBTCMD_DEPENDENCIES = libnl host-pkg-config
LIBTCMD_INSTALL_STAGING = YES

define LIBTCMD_BUILD_CMDS
    $(MAKE) -C $(@D) CC="$(TARGET_CC)" AR="$(TARGET_AR)" \
            PKGCONFIG=../../host/usr/bin/pkg-config
endef

$(eval $(call GENTARGETS))
$(eval $(generic-package))
