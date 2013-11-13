TARGETDIR=$1

export BR2_SDC_PLATFORM=wb45n

echo "WB45n POST BUILD script: starting..."

# source the common post build script
source "board/sdc/post_build_common.sh" "$TARGETDIR"

# Copy the product specific rootfs additions
tar c --exclude=.svn --exclude=.empty -C board/sdc/wb45n/rootfs-additions/ . | tar x -C $TARGETDIR/

# Services to disable by default
[ -f $TARGETDIR/etc/init.d/S??usbhost ] \
&& chmod a-x $TARGETDIR/etc/init.d/S??usbhost

chmod a+x $TARGETDIR/etc/init.d/S??lighttpd

chmod a+x $TARGETDIR/usr/bin/php-cgi

echo "WB45n POST BUILD script: done."
