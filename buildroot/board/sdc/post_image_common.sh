IMAGESDIR="$1"
TOPDIR="`pwd`"

echo "COMMON POST IMAGE script: starting..."

# enable tracing and exit on errors
set -x -e

cp "$IMAGESDIR/uImage"                "$IMAGESDIR/kernel.bin"
cp "$IMAGESDIR/rootfs.ubi"            "$IMAGESDIR/rootfs.bin"
cp "$IMAGESDIR/$BR2_SDC_PLATFORM.bin" "$IMAGESDIR/bootstrap.bin"

cp board/sdc/rootfs-additions-common/usr/sbin/fw_select "$IMAGESDIR/"
cp board/sdc/rootfs-additions-common/usr/sbin/fw_update "$IMAGESDIR/"

if [ -z "$LAIRD_FW_TXT_URL" ]; then
    LAIRD_FW_TXT_URL="http://`hostname`/$BR2_SDC_PRODUCT"
fi

cd "$IMAGESDIR" && "$TOPDIR/board/sdc/mkfwtxt.sh" "$LAIRD_FW_TXT_URL"

echo "COMMON POST IMAGE script: done."
