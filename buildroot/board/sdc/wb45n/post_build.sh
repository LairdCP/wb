TARGETDIR=$1

echo "WB45n POST BUILD script: starting..."

# source the common post build script
source "board/sdc/post_build_common.sh" "$TARGETDIR"

echo "WB45n POST BUILD script: done."
