TARGETDIR=$1

echo "WB40n POST BUILD script: starting..."

# source the common post build script
source "board/sdc/post_build_common.sh" "$TARGETDIR"

# Copy the product specific rootfs additions
tar c --exclude=.svn -C board/sdc/wb40n/rootfs-additions/ . | tar x -C $TARGETDIR/

echo "WB40n POST BUILD script: done."
