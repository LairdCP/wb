#############################################################
#
# mac+1 program
#
#############################################################

# source included in buildroot
MACPLUS1_VERSION = local
MACPLUS1_SOURCE =

define MACPLUS1_BUILD_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) \
		package/sdc/macplus1/mac+1.c -o $(@D)/mac+1
endef

define MACPLUS1_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 755 $(@D)/mac+1 $(TARGET_DIR)/usr/bin/
endef

define MACPLUS1_UNINSTALL_TARGET_CMDS
	rm -f $(TARGET_DIR)/usr/bin/mac+1
endef

$(eval $(call GENTARGETS))
$(eval $(generic-package))