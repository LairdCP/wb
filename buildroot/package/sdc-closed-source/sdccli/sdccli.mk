#############################################################
#
# SDC CLI
#
#############################################################

ifeq ($(BR2_PACKAGE_SDCCLI_PULL_FROM_SVN),y)
SDCCLI_VERSION = $(BR2_PACKAGE_SDCCLI_SVN_VERSION)
SDCCLI_SITE = svn://10.1.10.7/tests/sdc_cli/trunk
SDCCLI_SITE_METHOD = svn
else
SDCCLI_VERSION = local
SDCCLI_SITE = package/sdc-closed-source/externals/sdc_cli
SDCCLI_SITE_METHOD = local
endif

SDCCLI_DEPENDENCIES = libnl sdcsdk libedit
SDCCLI_MAKE_ENV = CC="$(TARGET_CC)" \
                  CXX="$(TARGET_CXX)" \
                  ARCH="$(KERNEL_ARCH)" \
                  CFLAGS="$(TARGET_CFLAGS)"
SDCCLI_TARGET_DIR = $(TARGET_DIR)

define SDCCLI_CONFIGURE_CMDS
    patch -d $(@D) < package/sdc-closed-source/sdccli/makefile.patch
endef

define SDCCLI_BUILD_CMDS
    $(MAKE) -C $(@D) clean
	$(SDCCLI_MAKE_ENV) $(MAKE) -C $(@D)
endef

define SDCCLI_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 755 $(@D)/bin/sdc_cli $(SDCCLI_TARGET_DIR)/usr/bin/sdc_cli
endef

define SDCCLI_UNINSTALL_TARGET_CMDS
	rm -f $(SDCCLI_TARGET_DIR)/usr/bin/sdc_cli
endef

$(eval $(generic-package))