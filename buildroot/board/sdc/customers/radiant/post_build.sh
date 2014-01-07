set -e -x

TARGETDIR=$1
echo
echo "NCR/Radiant POST BUILD ..."

# This post-build script will invoke wb40n post-build, which will also invoke
# the common post-build...
#
# Content will be copied from each rootfs, in order:
#  1. rootfs-additions-common
#  2. wb40n/rootfs-additions
#  3. radiant/rootfs-additions
#
# source the respective platform post build script
source "board/sdc/wb40n/post_build.sh" "$TARGETDIR"

# remove lighttpd and other cruft
rm -fr $TARGETDIR/var/www
rm -fr $TARGETDIR/etc/lighttpd

# copy the product specific rootfs-additions
tar c --exclude=.svn -C board/sdc/customers/radiant/rootfs-additions/ . \
  |tar x -C $TARGETDIR/

# enable/disable services
chmod -x /etc/init.d/S??lighttpd


echo "NCR/Radiant POST BUILD ...completed"
