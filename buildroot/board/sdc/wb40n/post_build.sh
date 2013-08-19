TARGETDIR=$1

export BR2_SDC_PLATFORM=wb40n

echo "WB40n POST BUILD script: starting..."

# source the common post build script
source "board/sdc/post_build_common.sh" "$TARGETDIR"

# Copy the product specific rootfs additions
tar c --exclude=.svn --exclude=.empty -C board/sdc/wb40n/rootfs-additions/ . | tar x -C $TARGETDIR/

echo "WB40n POST BUILD script: done."
