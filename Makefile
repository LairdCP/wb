# This makefile downloads buildroot from the buildroot website
# and prepares it for SDC WB40/45 building by doing the following:
# * unpack the tarfile
# * create a symbolic link for the uildroot directory names buildroot
# * add the SDC packages by linking
#     buildroot/packages/sdc -> package/sdc
#   and patching package/Config.in to include the sdc folder
# * create a symbolic link from
#     buildroot/board/sdc -> board/sdc

URL   := http://buildroot.uclibc.org/downloads/
VER   := 2011.11
PKG   := buildroot-$(VER)
ARCHV := $(PKG).tar.bz2

default: unpack.stamp
	$(MAKE) -C buildroot oldconfig
	$(MAKE) -C buildroot
	$(MAKE) -C images

product.selected:
	@echo "******************************************************************"
	@echo "Type 'make wb40n' or 'make wb45n' to select a product to work with"
	@echo "and then type 'make'. The selection is remembered."
	@echo "******************************************************************"
	@false

wb40n wb45n:
	echo "$@" > product.selected

unpack.stamp: product.selected $(ARCHV)
	# unpack buildroot, rename the directory to 'buildroot' for easier management versions
	tar xf $(ARCHV) --xform "s/^$(PKG)/buildroot/"
	# patch buildroot to add the sdc packages
	patch -p0 < buildroot-patches/sdc-package.patch
	# buildroot patch to work with non-standard placement of wb40n bootstrap board directory
	patch -p0 < buildroot-patches/at91bootstrap-wb40n.patch
	# backport custom patch config for at91bootstrap on 2011.11
	test "$(VER)" = 2011.11 && patch -p0 < buildroot-patches/at91bootstrap-custom-patch-dir.patch
	# add uboot version 2011.09 as an option
	test "$(VER)" = 2011.11 && patch -p0 < buildroot-patches/uboot-2011-09.patch
	# backport of at91bootstrap3 package
	patch -d buildroot -p1 < buildroot-patches/at91bootstrap3.patch
	# sync to dev_linux/buildroot/2011.11 rev 15835
	patch -d buildroot -p1 < buildroot-patches/buildroot-2011.11-lt1.patch
	# fix iproute parallel buiild race
	cp buildroot-patches/iproute2-fix-parallel-build-yacc.patch buildroot/package/iproute2/
	# install the config file
	cp buildroot/board/sdc/`cat product.selected`/configs/$(PKG).config buildroot/.config
	# mark operation as done
	touch unpack.stamp

$(ARCHV):
	wget -c $(URL)$(ARCHV)

clean:
	$(MAKE) -C buildroot clean

cleanall:
	find buildroot/ -mindepth 1 -maxdepth 1 -not -name board -not -name package -not -name '.svn' \
                -exec rm -rf "{}" ";"
	find buildroot/package buildroot/board  -mindepth 1 -maxdepth 1 \
                -not -name sdc -not -name sdc-closed-source -not -name '.svn' -exec rm -rf "{}" ";"
	rm -f unpack.stamp product.selected

.PHONY: default clean cleanall wb40n wb45n
.NOTPARALLEL:
