#!/bin/bash
# board/sdc/wbfs/wb_common.sh
# package/sdc/wbfs/wb_common.sh
# This script is designed to run via finalize-wrapper or package-wbfs (best).
#
# Dynamically, handles some common filesystem tweaking for wb-platform_name.
# a.) Removes some 'embedded' files/directories, that we do not want on the wb.
#
# b.) Implements work-around for 'makedev -d <device_table.txt>' feature/fault,
#    if a copy of the _table_txt file is available (must be done ahead of time).
#
# c.) Dynamically modifies /etc/{group,shadow,passwd,issue} files and creates a
#    directory in /home, based on the generic_hostname and generic_issue values
#    as set in BR2 configuration.
#
# jon.hefling@lairdtech.com


wbfs=$( pwd |grep /wbfs ) || { echo must run in sdc/wbfs; exit 2; }

# output/target
target=${TARGET_DIR:-$1}
[ -d "$target" ] || { echo TARGET_DIR not set; exit 2; }

brcfg=$target/../../.config

###
## wb_common configuration
# related items to keep or remove (comment-out to remove)
k_default=:
#k_ifup=:
#k_bash=:


# get some things from the buildroot configuration
device_table_txt=$( sed -n '/BR2_ROOTFS_DEVICE_TABLE/s/"//g;s/.*_TABLE=\(.*\)/\1/p' $brcfg )
gen_hostname=$( sed -n '/BR2_TARGET_GENERIC_HOSTNAME/s/"//g;s/.*_HOSTNAME=\(.*\)/\1/p' $brcfg )
gen_issue=$( sed -n '/BR2_TARGET_GENERIC_ISSUE/s/"//g;s/.*_ISSUE=\(.*\)/\1/p' $brcfg )

# for adding ${gen_hostname} as a user
if [ -n "$gen_hostname" ]
then
  echo "adding system user '$gen_hostname'"
  home_hostname=/home/${gen_hostname}
fi

# begin with the buildroot system skeleton tree
# and remove a few things we don't want
rm -f $target/etc/init.d/rcK
$k_ifup rm -fr $target/etc/network/if-*
$k_bash rm -f $target/root/.bash*
$k_bash rm -fr $target/etc/bash*


# also check that items in an existing *copy* of device_table.txt are compatible
if [ -f "$target/../build/${device_table_txt##*/}" ]
then
  ## Note that 'makedev -d generic/device_table.txt' is performed after
  ## the finalize-stage, and potentially conflicts with what we want to
  ## include or not, here, during finalize. (feature/fault)
  echo "dynamically adjusting *-device_table.txt entries"

  # dynamically add hostname as a user
  if [ -n "$gen_hostname" ] \
  && ! grep -q "${home_hostname}" ${device_table_txt}
  then
    # insert after /home/default
    let tsc=${#home_hostname}/8*3
    tabs="Ts Ts Ts Ts Ts "; Ts="${tabs:${tsc}}"
    sed -i "/\/home\/default/a${home_hostname}$Ts dTs 2755Ts 1001Ts 1001Ts -Ts -Ts ---" ${device_table_txt}
    sed -i "/${home_hostname}/s/Ts /\t/g" ${device_table_txt}
  fi

  # remove debian items we don't want
  $k_ifup sed -i 's,^/etc/network/if-.*,#&,' ${device_table_txt}

  sed -i 's,^/usr/share/udhcpc/default.script,#&,' ${device_table_txt}
fi


grep_add_to() {
  if ! grep -q "${2%%:*}" $target${1} 2>/dev/null
  then
    echo adding ${2%%:*}
    echo $2 >> $target${1} || { echo grep_add_to: $1 error; exit 1; }
  fi
}

# adjust etc/group
echo "writing: '/etc/group'"
grep_add_to /etc/group "lp:x:7:"
grep_add_to /etc/group "kmem:x:9:"
grep_add_to /etc/group "floppy:x:11:"
grep_add_to /etc/group "cdrom:x:19:"
grep_add_to /etc/group "dialout:x:20:"
grep_add_to /etc/group "tape:x:26:"
grep_add_to /etc/group "video:x:27:"
grep_add_to /etc/group "default:x:1000:"
if [ -n "$gen_hostname" ]
then
  grep_add_to /etc/group "${gen_hostname}:x:1001:"
fi

# adjust etc/passwd
if [ -n "$gen_hostname" ]
then
  echo "writing: '/etc/passwd'"
  grep_add_to /etc/passwd "${gen_hostname}:x:1001:1001:${gen_issue}:${home_hostname}:/bin/sh"
fi

# create etc/shadow
(
  set -e
  echo "writing: '/etc/shadow'"
  # using the local wbfs 'password.*' template files
  #
  # replace root, ftp, default
  sed '/root/d; /ftp/d; /default/d' -i $target/etc/shadow
  cat $wbfs/password.{root,ftp,default} >> $target/etc/shadow
  #
  if [ -n "$gen_hostname" ]
  then
    sed "s/hostname/${gen_hostname}/" \
      $wbfs/password.hostname >> $target/etc/shadow
  fi
) || exit 1


{ \
  # try to use multiple initials in hostname-release file
  initials=$( echo ${gen_issue} |sed -n 's/[a-z\ ]//g;p' ); \
  [ -n "${initials:1}" ] && gen_issue=$initials || :; \
}

# write and show the etc/hostname-release file
echo "${gen_issue} Linux Release `date +%Y%m%d`" \
  > $target/etc/${gen_hostname}-release || exit 1
echo "created: '/etc/${gen_hostname}-release'
  `cat $target/etc/${gen_hostname}-release`"

echo "done"

