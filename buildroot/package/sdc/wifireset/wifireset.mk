#############################################################
#
# WIFIRESET module
#
#############################################################

WIFIRESET_VERSION = 1.0
WIFIRESET_SOURCE =
WIFIRESET_DEPENDENCIES = linux

define WIFIRESET_CONFIGURE_CMDS
    cp $(TOPDIR)/package/sdc/wifireset/Makefile $(@D)
    cp $(TOPDIR)/package/sdc/wifireset/wifireset.c $(@D)
endef

define WIFIRESET_BUILD_CMDS
	$(MAKE) -C $(@D) $(LINUX_MAKE_FLAGS) KERNELDIR=$(LINUX_DIR)
endef
#    $(MAKE) -C $(@D) ARCH=arm CROSS_COMPILE="$(TARGET_CROSS)" \
#            KERNELDIR=$(TOPDIR)/$O/build/linux-3.3

define WIFIRESET_INSTALL_TARGET_CMDS
	$(MAKE) -C $(@D) $(LINUX_MAKE_FLAGS) KERNELDIR=$(LINUX_DIR) modules_install
endef

#	$(INSTALL) -D -m 644 $(@D)/wifireset.ko  \
#	    $(TOPDIR)/board/sdc/wb40n/rootfs-additions/lib/modules/wifireset.ko

$(eval $(call GENTARGETS))
$(eval $(generic-package))
