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

ifeq ($(WB_PLATFORM),)
	# issue warning
endif

define WBFS_INSTALL_TARGET_CMDS
	@( \
	  echo "--- Filesystem tuning for $${WB_PLATFORM} . . ." ;\
	  wb=$${WB_PLATFORM%%_*} ;\
	  if [ "$${wb}" != "$${WB_PLATFORM}" ] \
	  && [ "$${wb}_" != "$${WB_PLATFORM}" ] ;\
	  then \
	    wb=$${WB_PLATFORM} ;\
	  else \
	    wb=$${wb}_basic ;\
	  fi ;\
	  echo -e "\twb-platform_name: $${wb}" ;\
     cd $(WBFS_DIR) && echo -e "\twbfs: `pwd`" ;\
	  \
	  if [ -d "wb_common" ] ;\
	  then \
	    echo -e "\n--* Copying wbfs/wb_common/* \n\t-> $(TARGET_DIR)" ;\
	    rsync -rlp --exclude="\.[se][vm][np]*" wb_common/* $(TARGET_DIR) ;\
	  fi ;\
	  if [ -x "wb_common.sh" ] ;\
	  then \
	    echo "--> Running wb_common.sh" ;\
	    ./wb_common.sh $(TARGET_DIR) || echo ERROR ;\
	  fi ;\
	  \
	  if [ -d "$${wb}" ] ;\
	  then \
	    echo -e "\n--* Copying wbfs/$${wb}/* \n\t-> $(TARGET_DIR)" ;\
	    rsync -rlp --exclude="\.[se][vm][np]*" $${wb}/* $(TARGET_DIR) ;\
	  fi ;\
	  if [ -x "$${wb}.sh" ] ;\
	  then \
	    echo "--> Running $${wb}.sh" ;\
	    sh $${wb}.sh $(TARGET_DIR) || echo ERROR ;\
	  fi ;\
	  echo ;\
	)
endef

define WBFS_UNINSTALL_TARGET_CMDS
	# can't undo this stuff realistically 
endef

$(eval $(call GENTARGETS))
