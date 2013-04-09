set -e -x

TARGETDIR=$1
#
# applied in order:
# rootfs-additions-common
# wb40n/rootfs-additions
# carefusion/rootfs-additions
#
echo "Carefusion POST BUILD ..."

# source the respective platform post build script
source "board/sdc/wb40n/post_build.sh" "$TARGETDIR"

# copy the product specific rootfs-additions
tar c --exclude=.svn -C board/sdc/customers/carefusion/rootfs-additions/ . \
  |tar x -C $TARGETDIR/


# enable/disable services


echo "Carefusion POST BUILD ...completed"
