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

default: wb40n wb45n

wb40n wb45n: unpack.stamp
	# install the config file
	cp buildroot/board/sdc/$@/configs/$(PKG).config buildroot/output/$@/.config
	$(MAKE) O=output/$@ -C buildroot oldconfig
	$(MAKE) O=output/$@ -C buildroot
	$(MAKE) -C images $@

unpack.stamp: $(ARCHV)
	# unpack buildroot, rename the directory to 'buildroot' for easier management versions
	tar xf $(ARCHV) --xform "s/^$(PKG)/buildroot/"
	# patch buildroot to add the sdc properties
	patch -p0 < buildroot-patches/buildroot-sdc-board-config.patch
	# backport custom patch config for at91bootstrap on 2011.11
	test "$(VER)" = 2011.11 && patch -p0 < buildroot-patches/at91bootstrap-custom-patch-dir.patch
	# add uboot version 2011.09 as an option
	test "$(VER)" = 2011.11 && patch -p0 < buildroot-patches/uboot-2011-09.patch
	# backport of at91bootstrap3 package
	patch -d buildroot -p1 < buildroot-patches/at91bootstrap3.patch
	# sync to dev_linux/buildroot/2011.11 rev 17920
	patch -d buildroot -p1 < buildroot-patches/buildroot-2011.11-lt1.patch
	# fix iproute parallel buiild race
	cp buildroot-patches/iproute2-fix-parallel-build-yacc.patch buildroot/package/iproute2/
	# backport the dtb table support
	test "$(VER)" = 2011.11 && patch -p0 < buildroot-patches/buildroot-linux-dtb-backport.patch
	# install .config files so that buildroot is ready to go
	mkdir -p buildroot/output/wb40n buildroot/output/wb45n
	cp buildroot/board/sdc/wb40n/configs/$(PKG).config buildroot/output/wb40n/.config
	cp buildroot/board/sdc/wb45n/configs/$(PKG).config buildroot/output/wb45n/.config
	# mark operation as done
	touch unpack.stamp

$(ARCHV):
	wget -c $(URL)$(ARCHV)

source-wb40n:
	$(MAKE) -C buildroot O=output/wb40n source

source-wb45n:
	$(MAKE) -C buildroot O=output/wb45n source

source: source-wb40n source-wb45n

clean-wb40n:
	$(MAKE) -C buildroot O=output/wb40n clean
	rm -rf buildroot/output/wb40n/sdcbins

clean-wb45n:
	$(MAKE) -C buildroot O=output/wb45n clean
	rm -rf buildroot/output/wb45n/sdcbins

clean: clean-wb40n clean-wb45n

cleanall:
	find buildroot/ -mindepth 1 -maxdepth 1 -not -name board -not -name package -not -name '.svn' \
                -exec rm -rf "{}" ";"
	find buildroot/package buildroot/board  -mindepth 1 -maxdepth 1 \
                -not -name sdc -not -name sdc-closed-source -not -name '.svn' -exec rm -rf "{}" ";"
	rm -f unpack.stamp

.PHONY: default clean cleanall clean-wb40n clean-wb45n wb40n wb45n source source-wb40n source-wb45n
.NOTPARALLEL:
