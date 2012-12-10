#############################################################
#
# wb platform filesystem tuning
#
#############################################################

# everything is in this buildroot package
WBFS_VERSION = local
WBFS_SITE = package/sdc/wbfs
WBFS_SOURCE = package/sdc/wbfs
WBFS_SITE_METHOD = local
WBFS_INSTALL_TARGET = YES
WBFS_DEPENDENCIES = zlib

WBFS_DIR:=package/sdc/wbfs

define WBFS_INSTALL_TARGET_CMDS
	cd $(WBFS_DIR) && rsync -rlp --exclude="\.[se][vm][np]*" wb_common/* $(TARGET_DIR)
	cd $(WBFS_DIR) && ./wb_common.sh $(TARGET_DIR)
	cd $(WBFS_DIR) && rsync -rlp --exclude="\.[se][vm][np]*" $(BR2_SDC_PLATFORM)_basic/* $(TARGET_DIR)
    cd $(WBFS_DIR) && ./$(BR2_SDC_PLATFORM)_basic.sh $(TARGET_DIR)
endef

define WBFS_UNINSTALL_TARGET_CMDS
	# can't undo this stuff realistically 
endef

$(eval $(call GENTARGETS))
