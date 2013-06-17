IMAGESDIR="$1"

export BR2_SDC_PLATFORM=msd45n

echo "MSD45n POST IMAGE script: starting..."

# enable tracing and exit on errors
set -x -e

test -z "$BR2_SDC_PLATFORM" && export BR2_SDC_PRODUCT=msd45n
TARFILE="$IMAGESDIR/$BR2_SDC_PRODUCT.tar"

tar cf "$TARFILE" -C "$IMAGESDIR" rootfs.tar
tar f "$TARFILE" -C "$STAGING_DIR/usr" -u include/sdc_sdk.h
tar f "$TARFILE" -C "$STAGING_DIR/usr" -u include/sdc_events.h
tar f "$TARFILE" -C "$STAGING_DIR/usr" -u include/lrd_platspec.h
bzip2 -f "$TARFILE"

echo "MSD45n POST BUILD script: done."
