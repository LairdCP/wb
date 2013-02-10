TARGETDIR=$1

echo "COMMON POST BUILD script: starting..."

# enable tracing and exit on errors
set -x -e

# create firmware release file
echo "SDC Linux Release `date +%Y%m%d`" \
  > $TARGETDIR/etc/summit-release

# Set root password to ’root’. Password generated with
# mkpasswd, from the ’whois’ package in Debian/Ubuntu.
## sed -i ’s%^root::%root:8kfIfYHmcyQEE:%’ $TARGETDIR/etc/shadow

# Application/log file mount point
#mkdir -p $TARGETDIR/applog
## grep -q "^/dev/mtdblock7" $TARGETDIR/etc/fstab || \
## echo "/dev/mtdblock7\t\t/applog\tjffs2\tdefaults\t\t0\t0" \
## >> $TARGETDIR/etc/fstab

# Copy the common rootfs additions first so that they can be overriden,
# if necessary, by the product specific rootfs-additions
tar c --exclude=.svn -C board/sdc/rootfs-additions-common/ . | tar x -C $TARGETDIR/

# delete the default ssh init file
#rm -f $TARGETDIR/etc/init.d/S50sshd

# install libnl*.so.3 links
(   cd "$TARGETDIR/usr/lib" &&
    ln -sf libnl-3.so libnl.so.3 &&
    ln -sf libnl-genl-3.so libnl-genl.so.3  )

# Services to disable by default
chmod a-x "$TARGETDIR/etc/init.d/S59snmpd"
chmod a-x "$TARGETDIR/etc/init.d/S99lighttpd"

# copy the freshly built sdc binaries
if [ -d output/$BR2_SDC_PLATFORM/sdcbins ]; then
    cp -a output/$BR2_SDC_PLATFORM/sdcbins/* $TARGETDIR/
fi

# create missing symbolic link
# TODO: we shouldn't have to do this here, this is a temporary workaround
(cd $TARGETDIR/usr/lib && ln -sf "libsdc_sdk.so.1.0" "libsdc_sdk.so.1")

echo "COMMON POST BUILD script: done."
