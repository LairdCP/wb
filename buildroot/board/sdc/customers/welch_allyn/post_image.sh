IMAGESDIR="$1"

export BR2_SDC_PLATFORM=wb45n
export BR2_SDC_PRODUCT=welch_allyn

echo "Welch Allyn POST IMAGE script: starting..."

# enable tracing and exit on errors
set -x -e

# source the common post image script
source "board/sdc/post_image_common.sh" "$IMAGESDIR"

echo "Welch Allyn POST IMAGE script: done."
