#!/usr/bin/env ash
# /etc/network/wireless.sh - driver-&-firmware configuration
# Supports the Atheros ath6kl series driver.
# jon.hefling@lairdtech.com 20120520
#
WIFI_SUPP=/usr/bin/sdcsupp
WIFI_CONFIG=/etc/summit/wifi_interface.conf
WIFI_PROFILES=/etc/summit/profiles.conf
WIFI_LOG=/var/log/wifi

usleep='busybox usleep'
trap "" 1 15

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
    [ -n "$link" ] && [ $link -gt 0 ] && break
    #
    sleep 1
    cn_='\033[1K\r'
    let cn+=1 && msg -en .
    let sn=$cn%11
    if [ $sn -eq 0 ]
    then
      ps |grep -q "[ ]$WIFI_SUPP" \
      || { msg "supplicant not running, aborted"; return 1; }
    fi
  done
  #
  [ $cn -lt $1 ] \
  && { msg -e "${cn_}  ...associated:  time_${cn}s  link_${link##* }"; return 0; } \
  || { msg -e "${cn_}  ...failed to associate in ${cn}s"; return 1; }
}

wifi_checkinterface()
{
  # arg1 is timeout (10*mSec)
  msg "  ...checking $WIFI_DEV"
  let x=0
  while [ $x -lt $1 ]
  do
    grep -q $WIFI_DEV /proc/net/dev && break
    $usleep 10000 && { let x+=1; msg -en .; }
  done
  [ $x -gt 0 ] && msg
  [ $x -lt $1 ] && return 0 || return 1
}

wifi_queryinterface()
{
  [ -n "$1" ] \
  && WIFI_DEV=`sed -n "s/^device \(.*\).*/\1/p" $1 2>/dev/null`
  
  [ -z "$WIFI_DEV" ] \
  && WIFI_DEV=$( grep -s $WIFI_DRIVER /sys/class/net/*/device/uevent \
               |sed -n 's,/sys/class/net/\([a-z0-9]\+\)/device.*,\1,p' )
  
  [ -n "$WIFI_DEV" ] && return 0 || return 1
}

wifi_start()
{
  if grep -q ath6k /proc/modules
  then
    wifi_queryinterface $WIFI_LOG
  else
    echo -n >$WIFI_LOG
    ## Note: The pre-existence of the profiles.conf file is mandatory!!!
    # Simply calling the sdc_cli will regenerate the profiles.conf file.
    # If it is regenerated while the driver is loaded, trouble awaits...
    [ -f $WIFI_PROFILES ] \
    || { msg "re-generating $WIFI_PROFILES"; sdc_cli quit; }

    ## load the driver
    modprobe ath6kl_sdio \
    || { msg "  ...driver failed to load"; exit 1; }

    ## enumerated interface should be available upon load
    wifi_queryinterface \
    || { msg "  ...driver init failed, aborted"; return 1; }
    sed "s/^WIFI_INTERFACE.*/WIFI_INTERFACE=$WIFI_DEV/g" -i $WIFI_CONFIG
    echo "device $WIFI_DEV" >>$WIFI_LOG

    ## wait some (10*mSec) for interface to be ready
    wifi_checkinterface 67 \
    && { msg "  ...driver loaded, interface $WIFI_DEV available"; } \
    || { echo "  ...error, interface $WIFI_DEV is not available/usable"; return 1; }
  fi  
  msg activating $WIFI_DEV

  # try to enable interface  
  [ -n "$WIFI_DEV" ] \
  && /sbin/ifconfig $WIFI_DEV up 2>>$WIFI_LOG \
  || { msg iface $WIFI_DEV n/a, maybe fw issue, try: wireless restart; return 1; }

  # save MAC address for WIFI if necessary
  if [ -z "$WIFI_MACADDR" ]
  then
    WIFI_MACADDR=`cat /sys/class/net/$WIFI_DEV/address 2>/dev/null`
    sed "s/^WIFI_MACADDR.*/WIFI_MACADDR=$WIFI_MACADDR/g" -i $WIFI_CONFIG
  fi

  # launch supplicant as daemon if not running
  if ! ps |grep -q "[ ]$WIFI_SUPP"
  then
    msg -en launching: $WIFI_SUPP -i$WIFI_DEV $WIFI_80211 $WIFI_DEBUG -s'  '
    $WIFI_SUPP -i$WIFI_DEV $WIFI_80211 $WIFI_DEBUG -s >/dev/null 2>&1 &
    # the 'daemonize' option may have issues, but would allow dynamic usleep
    while [ ! -e /tmp/wpa_supplicant ]; do msg -en .; $usleep 1000000; done
    ps |grep -q "[ ]$WIFI_SUPP" || { msg ..error; return 1; }
    msg ..okay
  fi
  return 0
}

wifi_stop() {
  ##
  ## Stopping means packets can't use wifi and interface will be removed.
  ##
  if [ -n "$WIFI_DEV" ] \
  && grep -q $WIFI_DEV /proc/net/dev
  then
    ## de-configure the interface (flush settings) so packets don't use it
    # This step allows for a cleaner shutdown of the interface...
    # Otherwise, stale settings can remain.  Try 'ifconfig -a'.
    ifconfig $WIFI_DEV 0.0.0.0 && msg "  ...de-configured"

    ## terminate the supplicant
    if killall ${WIFI_SUPP##*/} 2>/dev/null
    then
      msg -en "supplicant terminating"
      while ps |grep -q "[ ]$WIFI_SUPP"; do $usleep 100000; msg -en .; done; msg
    fi
     
    ## down the interface
    msg -en "disabling interface  "
    ifconfig $WIFI_DEV down \
    && { $usleep 100000; msg ...down; } || msg
  fi
  ## and unload driver module
  if grep -q dhd /proc/modules
  then
    msg -en "unloading ath6k driver  "
    /sbin/modprobe -r ath6kl_sdio || { msg ...error; return 1; }
    msg ...okay
  fi
  return 0
}

# read configuration
if [ ! -f $WIFI_CONFIG ]
then
  echo "re-generating $WIFI_CONFIG"
  cat >$WIFI_CONFIG<<-	\
	wifi-configuration-file-block
	# $WIFI_CONFIG                                                           
	# This auto-generated file is read by the wireless.sh script.
	# Settings intended for the wb45nbt.
	# Edits can be made.

	# The interface name is enumerated from the following prefix.
	WIFI_PREFIX=wlan

	# Autoprobed if not set.
	WIFI_INTERFACE=

	# Autoprobed if not set.
	WIFI_MACADDR=

	# Timeout for association in seconds.
	WIFI_TIMEOUT=60

	# Driver device "name"
	WIFI_DRIVER="ath6kl_sdio"

	# The kernel driver module, firmware and nvram to load. (can be symlinks)
	WIFI_MODULE="/lib/modules/\`uname -r\`/kernel/drivers/net/wireless/ath/ath6kl/ath6kl_sdio.ko"
   WIFI_FIRMWARE=/lib/firmware/ath6kl
   WIFI_NVRAM=                       
	
	# Supplicant debugging can be set here or via commandline.
	#WIFI_DEBUG=-tdddd                                               

	# Supplicant can use nl80211
	WIFI_80211=-Dnl80211
	
	wifi-configuration-file-block
fi
source $WIFI_CONFIG || { echo "conf error"; exit 1; }

# ensure this script is available as system command
[ -x /sbin/wireless ] || ln -sf /etc/network/wireless.sh /sbin/wireless

# setting debug-mode from cmdline, overrides conf
[ "${1:0:1}" == "-" ] && WIFI_DEBUG=${1} && shift
[ -z "${WIFI_DEBUG:1}" ] && WIFI_DEBUG= #|| echo 6 >/proc/sys/kernel/printk

# optionally, wait on this script for a link
[ "$2" == "wait" ] && wfl=true || wfl=false

# command
case "$1" in
  
  stop|down)
    wifi_queryinterface $WIFI_LOG
    echo \ \ Stopping wireless $WIFI_DEV
    wifi_stop
    exit $?
    ;;

  start|up)
    echo \ \ Starting wireless
    wifi_start && $wfl && wifi_waitforlink $WIFI_TIMEOUT
    exit $?
    ;;

  restart)
    $0 $WIFI_DEBUG stop
    $0 $WIFI_DEBUG start $2
    ;;

  stat*)
    # show module
    lsmod |grep '^[Ma][ot][dh]'
    grep -q dhd /proc/modules || echo "  ...not loaded" 
    # show processes
    echo -e "\nAtheros:"
    ps -o pid,args |grep '[a]th'
    # show supplicant
    echo -e "\nSupplicant:"
    ps -o pid,args |grep 'sup[p]' || echo "  ...not running"
    echo
    echo "/proc/net/wireless:"
    cat /proc/net/wireless 2>/dev/null
    # try to find wireless interface and show if associated
    echo
    for x in /sys/class/net/*/wireless
    do
      x=${x##*/sys/class/net/}; x=${x%%/*}; [ "$x" != \* ] \
      && iw dev $x link |sed "s/onnected/ssociated/; s/cs/as/ ;s/Cs/As/"
    done
    echo
    exit 0
    ;;
    
  conf*)
    cat $WIFI_CONFIG
    exit $?
    ;;
    
  log)
    cat $WIFI_LOG
    exit $?
    ;;
    
  *)
    module=`ls -l "$WIFI_MODULE" |grep -o '[^ /]*$'`
    echo "$0"
    echo "Sets up the wireless ${module:-<-?->} driver and configures support for it."
    echo "Reads $WIFI_CONFIG.  (regenerated w/defaults, if missing)"
    echo
    echo "AP association is governed by the 'sdc_cli' and an active valid profile."
    echo "External calls to this script can wait on it, by adding option 'wait'."
    echo
    echo "Usage:"
    echo "# ${0##*/} [<-tdd...>] {start|stop|restart|status|conf|log} [{wait}]"
    exit 1
    ;;
esac
