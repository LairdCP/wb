TARGETDIR=$1

echo "WB40n POST BUILD script: starting..."

# source the common post build script
parentdir="`dirname "$0"`/.."
source "$parentdir/post_build_common.sh" "$TARGETDIR"

echo "WB40n POST BUILD script: done."
