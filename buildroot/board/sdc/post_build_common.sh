TARGETDIR=$1

echo "COMMON POST BUILD script: starting..."

# enable tracing and exit on errors
set -x -e

# Set root password to ’root’. Password generated with
# mkpasswd, from the ’whois’ package in Debian/Ubuntu.
## sed -i ’s%^root::%root:8kfIfYHmcyQEE:%’ $TARGETDIR/etc/shadow

# Application/log file mount point
#mkdir -p $TARGETDIR/applog
## grep -q "^/dev/mtdblock7" $TARGETDIR/etc/fstab || \
## echo "/dev/mtdblock7\t\t/applog\tjffs2\tdefaults\t\t0\t0" \
## >> $TARGETDIR/etc/fstab

# disable 3.8.0-laird1 ipv6 module to avoid ipv6-/-netlink conflict - temporary
if [ -f $TARGETDIR/lib/modules/3.8.0-laird1/kernel/net/ipv6/ipv6.ko ]
then
  mv -f $TARGETDIR/lib/modules/3.8.0-laird1/kernel/net/ipv6/ipv6.ko \
        $TARGETDIR/lib/modules/3.8.0-laird1/kernel/net/ipv6/-ipv6.ko
fi

# remove default ssh init file
# real version is in init.d/opt and works w/ inetd or standalone
rm -f $TARGETDIR/etc/init.d/S50sshd

# remove default lighttpd init
rm -f $TARGETDIR/etc/init.d/S50lighttpd

# remove bash cruft
rm -fr $TARGETDIR/etc/bash*
rm -f $TARGETDIR/root/.bash*

# remove debian cruft
rm -fr $TARGETDIR/etc/network/if-*

# remove buildroot cruft
rm -f $TARGETDIR/etc/os-release

# remove conflicting rcK
rm -f $TARGETDIR/etc/init.d/rcK

# Copy the rootfs-additions-common in place first.
# If necessary, these can be overwritten by the product specific rootfs-additions.
tar c --exclude=.svn -C board/sdc/rootfs-additions-common/ . | tar x -C $TARGETDIR/

# install libnl*.so.3 links
( cd "$TARGETDIR/usr/lib" \
  && ln -sf libnl-3.so libnl.so.3 \
  && ln -sf libnl-genl-3.so libnl-genl.so.3 )

# create missing symbolic link
# TODO: shouldn't have to do this here, temporary workaround
( cd $TARGETDIR/usr/lib \
  && ln -sf libsdc_sdk.so.1.0 libsdc_sdk.so.1 )
( cd $TARGETDIR/usr/lib \
  && ln -sf liblrd_platspec.so.1.0 liblrd_platspec.so.1 )

# Services to disable by default
[ -f $TARGETDIR/etc/init.d/S??lighttpd ] \
&& chmod a-x $TARGETDIR/etc/init.d/S??lighttpd
[ -f $TARGETDIR/etc/init.d/S??openvpn ] \
&& chmod a-x $TARGETDIR/etc/init.d/S??openvpn     #not ready for use

# Create default firmware description file.
# This may be overwritten by a proper release file.
if [ -z "$LAIRD_RELEASE_STRING" ]; then
  echo "Laird Linux development build `date +%Y%m%d`" \
    > $TARGETDIR/etc/summit-release
else
  echo "$LAIRD_RELEASE_STRING" > $TARGETDIR/etc/summit-release
fi

echo "COMMON POST BUILD script: done."
