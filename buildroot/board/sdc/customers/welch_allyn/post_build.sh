set -e -x

TARGETDIR=$1

echo "Welch Allyn POST BUILD script: starting..."

# source the common post build script
source "board/sdc/wb45n/post_build.sh" "$TARGETDIR"

# Copy the product specific rootfs additions
tar c --exclude=.svn -C board/sdc/customers/welch_allyn/rootfs-additions/ . | tar x -C $TARGETDIR/


echo "Welch Allyn POST BUILD script: done."
