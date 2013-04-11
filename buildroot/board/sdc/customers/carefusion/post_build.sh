set -e -x

TARGETDIR=$1
echo
echo "Carefusion POST BUILD ..."

# This post-build script will invoke wb40n post-build, which will also invoke
# the common post-build...
#
# Content will be copied from each rootfs, in order:
#  1. rootfs-additions-common
#  2. wb40n/rootfs-additions
#  3. carefusion/rootfs-additions
#
# source the respective platform post build script
source "board/sdc/wb40n/post_build.sh" "$TARGETDIR"

# remove lighttpd and other cruft
rm -fr $TARGETDIR/var/www
rm -fr $TARGETDIR/etc/lighttpd

# remove bluetooth cruft
rm -f $TARGETDIR/etc/init.d/opt/S95bluetooth
rm -f $TARGETDIR/etc/summit/bluetooth.conf
rm -f $TARGETDIR/etc/summit/BCM*.hcd


# copy the product specific rootfs-additions
tar c --exclude=.svn -C board/sdc/customers/carefusion/rootfs-additions/ . \
  |tar x -C $TARGETDIR/


# enable/disable services


echo "Carefusion POST BUILD ...completed"
