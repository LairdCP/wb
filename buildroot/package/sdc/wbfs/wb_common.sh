#!/bin/bash
# board/sdc/wbfs/wb_common.sh
# package/sdc/wbfs/wb_common.sh
# This script is designed to run via finalize or package-wbfs.
#
# Handles common filesystem tweaking for wb-platform_name.
# jon.hefling@lairdtech.com

wbfs=$( pwd |grep /wbfs ) || { echo must run in sdc/wbfs; exit 2; }

target=${TARGET_DIR:-$1}
[ -d "$target" ] || { echo TARGET_DIR not set; exit 2; }

brcfg=$target/../../.config
[ -f $brcfg ] || { echo cannot find buildroot output/.config; exit 2; } 


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

# also check that items in an existing copy of device_table.txt are compatible
if [ -f "$target/../build/${device_table_txt##*/}" ]
then
  # Note that 'makedev -d generic/device_table.txt' is performed after
  # the finalize-stage, and potentially conflicts with what we want to
  # include or not, during this operation.

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

  # remove items we don't want
  $k_ifup sed -i 's,^/etc/network/if-.*,#&,' ${device_table_txt} 2>/dev/null

  sed -i 's,^/usr/share/udhcpc/default.script,#&,' ${device_table_txt} 2>/dev/null
fi


grep_add_to() {
  if ! grep -q "${2%%:*}" $target${1}
  then
    echo wrote to $1
    echo $2 >> $target${1} 
  fi
}

# adjust etc/passwd
if [ -n "$gen_hostname" ]
then
  grep_add_to /etc/passwd "${gen_hostname}:x:1001:1001:${gen_issue}:${home_hostname}:/bin/sh"
fi

# adjust etc/group
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

# create etc/shadow
cat $wbfs/password.root > $target/etc/shadow.NEW
sed '/root/d; /ftp/d; /default/d' $target/etc/shadow \
  >> $target/etc/shadow.NEW
cat $wbfs/password.ftp >> $target/etc/shadow.NEW
cat $wbfs/password.default >> $target/etc/shadow.NEW
if [ -n "$gen_hostname" ]
then
  sed "s/hostname/${gen_hostname}/" $wbfs/password.hostname \
    >> $target/etc/shadow.NEW
fi
mv -f $target/etc/shadow.NEW $target/etc/shadow

{ \
  # ensure links for libnl
  cd $target/usr/lib; \
  ln -sf libnl-3.so libnl.so.3; \
  ln -sf libnl-genl-3.so libnl-genl.so.3; \
}

{ \
  # try to use multiple initials in hostname-release file
  initials=$( echo ${gen_issue} |sed -n 's/[a-z\ ]//g;p' ); \
  [ -n "${initials:1}" ] && gen_issue=$initials || :; \
}

# write and show the etc/hostname-release file
echo "${gen_issue} Linux Release `date +%Y%m%d`" \
  > $target/etc/${gen_hostname}-release
echo "wrote to '/etc/${gen_hostname}-release'
  `cat $target/etc/${gen_hostname}-release`"

echo "done"
exit 0
