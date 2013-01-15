TARGETDIR=$1

export BR2_SDC_PLATFORM=wb45n

echo "WB45n POST BUILD script: starting..."

# source the common post build script
source "board/sdc/post_build_common.sh" "$TARGETDIR"

# Copy the product specific rootfs additions
tar c --exclude=.svn -C board/sdc/wb45n/rootfs-additions/ . | tar x -C $TARGETDIR/

echo "WB45n POST BUILD script: done."
