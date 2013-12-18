set -e -x

TARGETDIR=$1

echo "Radiant POST BUILD script: starting..."

source "board/sdc/wb40n/post_build.sh" "$TARGETDIR"

# Copy the product specific rootfs-additions
tar c --exclude=.svn -C board/sdc/customers/welch_allyn/rootfs-additions/ . \
| tar x -C $TARGETDIR/




echo "POST BUILD script: done."
