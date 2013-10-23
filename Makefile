# This makefile downloads buildroot from the buildroot website
# and prepares it for Laird WB40/45 building

# if BUILDROOT_DL_DIR is set, archives are downloaded to BUILDROOT_DL_DIR
LAIRD_DL_DIR := archive
ifdef BUILDROOT_DL_DIR
LAIRD_DL_DIR := $(BUILDROOT_DL_DIR)
LAIRD_ARCHIVES := archive/AT91Bootstrap-v3.4.4.tar.xz \
                  archive/msd45n-laird_fips-3.4.1.1.tar.bz2 \
				  archive/msd40n-laird-3.4.1.1.tar.bz2 \
                  archive/openssl-fips-2.0.5.tar.gz
endif

URL   := http://buildroot.uclibc.org/downloads/
VER   := 2013.02
PKG   := buildroot-$(VER)
ARCHV := $(PKG).tar.bz2

default: wb45n

all: wb45n

<<<<<<< HEAD
wb45n: unpack.stamp
=======
msd40n msd45n msd45n_fips welch_allyn carefusion wb40n wb45n wb45n_devel wb40n_devel: unpack.stamp
>>>>>>> master
	# install the config file
	$(MAKE) -C buildroot $@_defconfig
	$(MAKE) -C buildroot
	$(MAKE) -C images $@

unpack: unpack.stamp
unpack.stamp: $(LAIRD_DL_DIR)/$(ARCHV)
ifdef BUILDROOT_DL_DIR
	# copy the Laird archives into the override buildroot directory
	cp -n $(LAIRD_ARCHIVES) $(BUILDROOT_DL_DIR)/
endif
	# unpack buildroot, rename the directory to 'buildroot' for easier management
	tar xf $(LAIRD_DL_DIR)/$(ARCHV) --xform "s/^$(PKG)/buildroot/"
	patch -d buildroot -p1 < buildroot-patches/buildroot-2013.02-laird1.patch
	patch -d buildroot -p1 < buildroot-patches/wireless-regdb.patch
	patch -d buildroot -p1 < buildroot-patches/crda.patch
	patch -d buildroot -p1 < buildroot-patches/strip_whitespace_device_table.patch
	patch -d buildroot -p1 -R < buildroot-patches/external-toolchain-relocatable.patch
	# link the board configs as *_defconfig names
<<<<<<< HEAD
=======
	cd buildroot/configs && ln -s ../board/sdc/customers/welch_allyn/configs/buildroot.config welch_allyn_defconfig
	cd buildroot/configs && ln -s ../board/sdc/customers/carefusion/configs/buildroot.config carefusion_defconfig
	cd buildroot/configs && ln -s ../board/sdc/wb40n/configs/buildroot.config wb40n_defconfig
	cd buildroot/configs && ln -s ../board/sdc/wb40n/configs/buildroot-wb40n_devel.config wb40n_devel_defconfig
>>>>>>> master
	cd buildroot/configs && ln -s ../board/sdc/wb45n/configs/buildroot.config wb45n_defconfig
	# mark operation as done
	touch unpack.stamp

$(LAIRD_DL_DIR)/$(ARCHV):
	wget -nc -c $(URL)$(ARCHV) -O $@

source:
	$(MAKE) -C buildroot source

clean:
	$(MAKE) -C buildroot clean

cleanall:
	find buildroot/ -mindepth 1 -maxdepth 1 -not -name board -not -name package -not -name laird-devel \
                    -not -name '.svn' -not -name '.git' \
                    -exec rm -rf "{}" ";"
	find buildroot/package buildroot/board  -mindepth 1 -maxdepth 1 \
                -not -name sdc -not -name sdc-closed-source -not -name sdc-devel \
                -not -name '.svn' -not -name .git \
                -exec rm -rf "{}" ";"
	rm -f unpack.stamp
	
legal-info-wb45n:
	$(MAKE) -C buildroot O=output/wb45n legal-info

<<<<<<< HEAD
.PHONY: default all unpack clean cleanall wb45 source
=======
legal-info-wb40n:
	$(MAKE) -C buildroot O=output/wb40n legal-info	

legal-info: legal-info-wb40n legal-info-wb45n
	
.PHONY: default all unpack clean cleanall clean-wb40n clean-wb45n wb40n wb45n \
        source source-wb40n source-wb45n clean-sdc-pkg clean-wb40n-sdc-pkg clean-wb45n-sdc-pkg welch_allyn carefusion
>>>>>>> master
.NOTPARALLEL:
