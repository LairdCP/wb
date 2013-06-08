TARGETDIR=$1

export BR2_SDC_PLATFORM=wb45n

echo "MSD45n POST BUILD script: starting..."

# enable tracing and exit on errors
set -x -e

# cleanup
rm -f  -- $TARGETDIR/lib64 $TARGETDIR/usr/lib64
rm -rf -- $TARGETDIR/var $TARGETDIR/etc
rm -rf -- $TARGETDIR/usr/share
rm -rf -- $TARGETDIR/usr/sbin/nl* $TARGETDIR/usr/sbin/genl*
rm -f  -- $TARGETDIR/sbin/regdbdump
rm -f  -- $TARGETDIR/usr/lib/libstdc++*
rm -f  -- $TARGETDIR/usr/lib/terminfo
rm -f  -- $TARGETDIR/lib/ld-*
rm -f  -- $TARGETDIR/lib/libc[.-]*so*
rm -f  -- $TARGETDIR/lib/libdl[.-]*so*
rm -f  -- $TARGETDIR/lib/libm[.-]*so*
rm -f  -- $TARGETDIR/lib/libnsl[.-]*so*
rm -f  -- $TARGETDIR/lib/libnss[._-]*so*
rm -f  -- $TARGETDIR/lib/libpthread[.-]*so*
rm -f  -- $TARGETDIR/lib/libresolv[.-]*so*
rm -f  -- $TARGETDIR/lib/libcrypt[.-]*so*
rm -f  -- $TARGETDIR/lib/librt[.-]*so*
rm -f  -- $TARGETDIR/lib/libutil[.-]*so*
rm -f  -- $TARGETDIR/lib/libgcc_s[.-]*so*

# copy firmware files
mkdir -p $TARGETDIR/lib/firmware
tar c --exclude=.svn -C board/sdc/wb45n/rootfs-additions/lib/firmware . | tar x -C $TARGETDIR/lib/firmware

# create missing symbolic link
# TODO: shouldn't have to do this here, temporary workaround
( cd $TARGETDIR/usr/lib \
  && ln -sf libsdc_sdk.so.1.0 libsdc_sdk.so.1 )

echo "MSD45n POST BUILD script: done."
