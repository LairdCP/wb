IMAGESDIR="$1"

export BR2_SDC_PLATFORM=wb45n

echo "MSD45n POST IMAGE script: starting..."

# enable tracing and exit on errors
set -x -e

TARFILE="$IMAGESDIR/msd45n.tar"

tar cf "$TARFILE" -C "$IMAGESDIR" rootfs.tar
tar f "$TARFILE" -C "$STAGING_DIR/usr" -u include/sdc_sdk.h
tar f "$TARFILE" -C "$STAGING_DIR/usr" -u include/sdc_events.h
bzip2 -f "$TARFILE"

echo "MSD45n POST BUILD script: done."
