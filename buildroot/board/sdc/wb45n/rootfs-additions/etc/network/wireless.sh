#!/usr/bin/env ash
# /etc/network/wireless.sh - driver-&-firmware configuration
# jon.hefling@lairdtech.com 20120520
#
WIFI_PREFIX=wlan                                ## iface prefix to be enumerated
WIFI_DRIVER="ath6kl_sdio"                       ## device driver "name"
WIFI_MODULE=/lib/modules/`uname -r`/kernel/drivers/net/wireless/ath/ath6kl/ath6kl_sdio.ko
#WIFI_FWPATH=/lib/firmware                       ## location of 'fw' symlink
#WIFI_NVRAM=/lib/nvram/nv

WIFI_PROFILES=/etc/summit/profiles.conf         ## sdc_cli profiles.conf
WIFI_MACADDR=/etc/summit/wifi_interface         ## persistent mac-address file

# supplicant and cli - comment out to disable
SDC_SUPP=/usr/bin/sdcsupp
SDC_CLI=/usr/bin/sdc_cli

# supplicant options
WIFI_80211=-Dnl80211                            ## supplicant driver nl80211
#WIFI_DEBUG=-tdddd                               ## supplicant debug option 

#WIFI_FIPS=y                                     ## enable FIPS mode


wifi_config()
{
  ## Note: The pre-existence of the profiles.conf file is mandatory!!!
  # Simply calling the sdc_cli will regenerate the profiles.conf file.
  # If it is regenerated while the driver is loaded, trouble awaits...
  [ -f $WIFI_PROFILES ] \
  || { msg "re-generating $WIFI_PROFILES"; ${SDC_CLI:-:} quit; }
}

msg()
{
  # display to stdout if not via init/rcS
  [ -n "$rcS_" ] && echo "$@" >>$rcS_log || echo "$@"
}

wifi_waitforlink()
{
  # arg1 is timeout (Sec) to obtain association/link
  { set +x; } 2>/dev/null
  msg "checking for association"
  let cn=0
  while [ $cn -lt $1 ]
  do
    { read -r link </sys/class/net/$WIFI_DEV/wireless/link; } 2>/dev/null
    let $link+0 && break || sleep 1
    cn_='\033[1K\r'
    let cn+=1 && msg -en .
    let sn=$cn%11
    if [ $sn -eq 0 ]
    then
      ps |grep -q "[ ]$SDC_SUPP" \
      || { msg "supplicant not running, aborted"; return 1; }
    fi
  done
  #
  [ $cn -lt $1 ] \
  && { msg -e "${cn_}  ...associated:  time_${cn}s  link_${link##* }"; return 0; } \
  || { msg -e "${cn_}  ...failed to associate in ${cn}s"; return 1; }
}

wifi_awaitinterface()
{
  # arg1 is timeout (10*mSec) to await availability
  let x=0
  while [ $x -lt $1 ]
  do
    grep -q "${WIFI_DEV:-xx}" /proc/net/dev && break
    $usleep 10000 && { let x+=1; msg -en .; }
  done
  #[ $x -gt 0 ] && msg
  [ $x -lt $1 ] && return 0 || return 1
}

wifi_queryinterface()
{
  # determine iface via path with matching device/uevent (do not quote token)
  WIFI_DEV=$( grep -s $WIFI_DRIVER /sys/class/net/*/device/uevent \
               |sed -n 's,/sys/class/net/\([a-z0-9]\+\)/device.*,\1,p' )

  if [ -z "$WIFI_DEV" ]
  then
    return 1
  elif let $1+0
  then
    wifi_awaitinterface $1 || return 1
  fi
  return 0
}

wifi_fips()
{
  modprobe sdc2u
  mode=664
  grp=staff
  major=$( sed -n '/sdc2u/s/^[ ]*\([0-9]*\).*/\1/p' /proc/devices )
  minor=0
  rm -f /dev/sdc2u0
  mknod /dev/sdc2u0 c $major $minor

  sdcu &
  # maybe need to check if successful...

  WIFI_FIPS=wifi_fips=y
}

wifi_start()
{
  if grep -q ${module/.ko/} /proc/modules
  then
    wifi_queryinterface
  else
    ## check for 'slot_b=' setting in kernel args
    grep -o 'slot_b=.' /proc/cmdline \
    && msg "warning: \"slot_b\" setting in bootargs"

    ## start daemon for fips mode
    test -n "$WIFI_FIPS" && wifi_fips
    
    ## load the driver
    modprobe ath6kl_core
    #modprobe ath6kl_sdio
    
    insmod $WIFI_MODULE $WIFI_FIPS \
    || { msg "  ...driver failed to load"; exit 1; }

    ## await enumerated interface
    wifi_queryinterface 67 \
    || { msg "  ...driver init failure, iface not available: ${WIFI_DEV:-?}"; return 1; }
    #&& { msg "  ...success"; } \
  fi

  # enable interface  
  [ -n "$WIFI_DEV" ] \
  && { msg "activate: $WIFI_DEV  ...`ifconfig $WIFI_DEV up 2>&1 && echo okay`"; } \
  || { msg iface $WIFI_DEV n/a, maybe fw issue, try: wireless restart; return 1; }

  # save MAC address for WIFI if necessary
  grep -sq ..:..:..:..:..:.. $WIFI_MACADDR \
  || cat /sys/class/net/$WIFI_DEV/address >$WIFI_MACADDR

  # launch supplicant if exists and not already running
  if test -e "$SDC_SUPP" && ! ps |grep -q "[ ]$SDC_SUPP" && let n=17
  then
    [ -f $wpa_sd/*.pid ] \
    && { msg "$wpa_sd/*.pid exists"; return 1; }
    
    msg -en executing: $SDC_SUPP -i$WIFI_DEV $WIFI_80211 $WIFI_DEBUG -s'  '
    $SDC_SUPP -i$WIFI_DEV $WIFI_80211 $WIFI_DEBUG -s >/dev/null 2>&1 &
    #
    # the 'daemonize' option may have issues, so using dynamic wait instead
    until test -e $wpa_sd || ! let n=$n-1; do msg -en .; $usleep 500000; done
    # check that supplicant is running and store its process id
    pidof ${SDC_SUPP##*/} 2>/dev/null >$wpa_sd/${SDC_SUPP##*/}.pid \
    || { msg ..error; return 1; }
    msg ..okay
  fi
  return 0
}

wifi_stop()
{
  ## Stopping means packets can't use wifi and interface will be removed.
  ##
  if [ -n "$WIFI_DEV" ] \
  && grep -q $WIFI_DEV /proc/net/dev
  then
    ## de-configure the interface
    # This step allows for a cleaner shutdown by flushing settings,
    # so packets don't use it.  Otherwise stale settings can remain.
    ifconfig $WIFI_DEV 0.0.0.0 && msg "  ...de-configured"

    ## terminate the supplicant by looking up its process id
    let pid=$( grep -s ^ $wpa_sd/*.pid )+0 && rm -f $wpa_sd/*.pid
    if kill $pid 2>/dev/null
    then
      msg -en "supplicant terminating"
      while [ -d /proc/$pid ]; do $usleep 50000; msg -en .; done; msg
    fi

    ## down the interface
    # There have been occasional problems when the driver is unloaded
    # while the iface is still being used.
    msg -en "disabling interface  "
  # ${SDC_CLI:-:} disable
    ifconfig $WIFI_DEV down && { $usleep 100000; msg ...down; } || msg
  fi
  ## unload driver module
  if grep -qs ${module/.ko/} /proc/modules
  then
    msg -en "unloading ${module/.ko/} driver  "
    modprobe -r ${module/.ko/} || { msg ...error; return 1; }
    msg ...okay
  fi
  return 0
}

# ensure this script is available as system command
[ -x /sbin/wireless ] || ln -sf /etc/network/wireless.sh /sbin/wireless

# setting debug-mode from cmdline, overrides conf
case $1 in
  -[td]*)
    WIFI_DEBUG=${1} && shift
    ;;
esac
#[ -z "${WIFI_DEBUG:1}" ] && WIFI_DEBUG= || echo 6 >/proc/sys/kernel/printk

# optionally, wait on this script for a link
[ "$2" == "wait" ] && wfl=true || wfl=false

wpa_sd=/tmp/wpa_supplicant
module=${WIFI_MODULE##*/}
usleep='busybox usleep'
trap "" 1 15

# command
case $1 in
  
  stop|down)
    wifi_queryinterface
    echo \ \ Stopping wireless $WIFI_DEV
    wifi_stop
    ;;

  start|up)
    echo \ \ Starting wireless
    wifi_config && wifi_start && $wfl && wifi_waitforlink 60
    ;;

  restart)
    $0 $WIFI_DEBUG stop && exec $0 $WIFI_DEBUG start $2
    ;;

  '')
    module=${module/.ko/}
    lsmod |grep -e ^Module -e "$module"
    grep -q "^$module" /proc/modules \
    || echo "  ...not loaded" 

    echo -e "\nProcesses related for this driver and supplicant:"
    top -bn1 \
    |sed -n '/sed/d;4H;/'"${SDC_SUPP##*/}"'/H;/'"${module%%_*}"'/{H;x;p;}' |uniq \
    |grep . || echo "  ...not found"

    if wifi_queryinterface
    then
      sed 's/^Inter-/\n\/proc\/net\/wireless:\n&/;$a' \
        /proc/net/wireless 2>/dev/null || echo

      iw dev $WIFI_DEV link \
        |sed 's/onnec/ssocia/;s/cs/as/;s/Cs/As/;s/(.*)//;/[RT]X:/d;/^$/,$d'
    fi
    echo
    ;;
    
  \?|-h|--help)
    echo "$0"
    echo "  ...stop/start/restart the '$WIFI_PREFIX#' interface"
    echo "Manages the '$WIFI_DRIVER' wireless device driver: $module"
    echo
    echo "AP association is governed by the 'sdc_cli' and an active profile."
    echo "External calls can wait on association, by adding option 'wait'."
    echo
    [ "settings" == "$2" ] && grep "^WIFI_[A-Z]*=" $0 && echo
    echo "Flags:  (passed to supplicant)"
    echo "  -t  timestamp debug messages"
    echo "  -d  debug verbosity (-dd even more)"
    echo
    echo "Usage:"
    echo "# ${0##*/} [-tdddd] {stop|start|restart|status} [wait]"
    ;;

  *)
    echo "$0 ? [settings]"
    false
    ;;
esac
exit $?
