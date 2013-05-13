IMAGESDIR="$1"

export BR2_SDC_PLATFORM=wb45n

echo "WB45n POST IMAGE script: starting..."

# enable tracing and exit on errors
set -x -e

TARFILE="$IMAGESDIR/msd45n.tar"
SDKDIR=package/sdc-closed-source/externals/sdk

tar cf "$TARFILE" -C "$IMAGESDIR" rootfs.tar
tar f "$TARFILE" -C "$SDKDIR" -u include/sdc_sdk.h
tar f "$TARFILE" -C "$SDKDIR" -u include/sdc_events.h
bzip2 -f "$TARFILE"

echo "WB45n POST BUILD script: done."
