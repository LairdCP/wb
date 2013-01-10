#!/bin/sh
# /etc/network/wireless.sh - driver-&-firmware configuration
# Supports the Atheros ath6kl series driver.
# jon.hefling@lairdtech.com 20120520
#
trap "" 1 15
WIFI_CONFIG=/etc/summit/wifi_interface.conf
WIFI_PROFILES=/etc/summit/profiles.conf
WIFI_LOG=/var/log/wifi

msg()
{
  # display to stdout if not via init/rcS
  [ -n "$rcS_" ] && echo "$@" >>$rcS_log || echo "$@"
}

# arg1 is timeout (Sec) to obtain association/link
wifi_waitforlink()
{
  msg "checking for association"
  set +x >/dev/null
  let cn=0
  while [ $cn -lt $1 ]
  do
    link=$( cat /sys/class/net/$WIFI_DEV/wireless/link 2>/dev/null )
    [ -n "$link" ] && [ $link -gt 0 ] && break
    #
    sleep 1
    cn_='\033[1K\r'
    let cn+=1 && msg -en .
    let sn=$cn%11
    if [ $sn -eq 0 ]
    then
      ps |grep -q 'sup[p]' \
      || { msg "supplicant not running, aborted"; return 1; }
    fi
  done
  #
  [ $cn -lt $1 ] \
  && { msg -e "${cn_}  ...associated:  time_${cn}s  link_${link##* }"; return 0; } \
  || { msg -e "${cn_}  ...failed to associate in ${cn}s"; return 1; }
}

# arg1 is timeout (10*mSec)
wifi_checkinterface()
{
  msg "  ...checking $WIFI_DEV"
  let x=0
  while [ $x -lt $1 ]
  do
    grep -q $WIFI_DEV /proc/net/dev && break
    busybox usleep 10000 && let x+=1 && msg -en .
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
  grep -q ath6k /proc/modules && {
    wifi_queryinterface $WIFI_LOG
  } || {
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
    || { msg "  ...driver init failed, aborted"; exit 1; }
    sed "s/^WIFI_INTERFACE.*/WIFI_INTERFACE=$WIFI_DEV/g" -i $WIFI_CONFIG
    echo "device $WIFI_DEV" >>$WIFI_LOG

    ## wait some (10*mSec) for interface to be ready
    wifi_checkinterface 67 \
    && { msg "  ...driver loaded, interface $WIFI_DEV available"; } \
    || { echo "  ...error, interface $WIFI_DEV is not available/usable"; exit 1; }
  }  
  msg "activating $WIFI_DEV"

  # try to enable interface  
  [ -n "$WIFI_DEV" ] \
  && /sbin/ifconfig $WIFI_DEV up 2>>$WIFI_LOG \
  || { msg "dev $WIFI_DEV n/a, maybe fw issue, try: wireless restart"; exit 1; }

  # save MAC address for WIFI if necessary
  if [ -z "$WIFI_MACADDR" ]
  then
    WIFI_MACADDR=`cat /sys/class/net/$WIFI_DEV/address 2>/dev/null`
    sed "s/^WIFI_MACADDR.*/WIFI_MACADDR=$WIFI_MACADDR/g" -i $WIFI_CONFIG
  fi

  # launch supplicant as daemon if not running
  if ! ps |grep -q 'sdcsup[p]'
  then
    msg "launching supplicant"
    /usr/bin/sdcsupp -s $WIFI_80211 $WIFI_DEBUG -i $WIFI_DEV >/dev/null 2>&1 &
  fi
}

#
# WARNING:
# deconfig of iface - disabled per request, stale settings will persist (ifconfig -a)
# termination of apps using iface - disabled per request, there may be conflicts
#                                                       
wifi_stop() {
  if [ -n "$WIFI_DEV" ] \
  && grep -q $WIFI_DEV /proc/net/dev
  then
#   msg "deconfiguring $WIFI_DEV"
#   ifconfig $WIFI_DEV 0.0.0.0
    #
#   f='\ \ *\([^ ][^ ]*\)'
#   for pid in \
#   $( ps |sed -n "/sed/d/$WIFI_DEV/s/^\ *\([0-9]*\)${f}${f} [^ ].*$/\1=\3/p" )
#   do
#     [ $PPID -eq ${pid%%=*} ] && { msg "$pid ...skipping"; continue; }
#     kill $k9 ${pid%%=*} \
#     && msg `printf "%5d %s terminated\n" ${pid%%=*} ${pid##*=}`
#     # have to kill off anything using interface or it won't be a clean stop
#   done
    msg "disabling $WIFI_DEV ..."
    #/usr/bin/sdc_cli disable >/dev/null 2>&1
    ifconfig $WIFI_DEV down 2>>$WIFI_LOG
  fi
  if [ "${WIFI_DRIVER_UNLOAD_ENABLE:0:1}" == "y" ] \
  && grep -q ath6k /proc/modules
  then
    msg -en "unloading ath6k driver"; modprobe -r ath6kl_sdio
  fi
  [ $? ] && { msg "  ...okay"; return 0; } || { msg "  ...error"; return 1; }
}

# auto-create config if not existing
if [ ! -f $WIFI_CONFIG ]
then
  echo "re-generating $WIFI_CONFIG"
  mkdir -p ${WIFI_CONFIG%/*}
  cat >$WIFI_CONFIG<<-  end-of-wifi-configuration-file-block
	# $WIFI_CONFIG                                                           

	# The interface name is enumerated from the following prefix.
	WIFI_PREFIX=wlan

	# Autoprobed.
	WIFI_INTERFACE=
	
	# Autoprobed.
	WIFI_MACADDR=
	
	# Timeout for association in seconds.
	WIFI_TIMEOUT=60
	
	# Driver device "name"
	WIFI_DRIVER="ath6kl_sdio"
	
	# The kernel driver module, firmware and nvram to load. (can be symlinks)
	WIFI_MODULE="/lib/modules/\`uname -r\`/kernel/drivers/net/wireless/ath/ath6kl/ath6kl_sdio.ko"
	WIFI_FIRMWARE=/lib/firmware/ath6kl
	WIFI_NVRAM=

	# Whether the module should be unloaded when wireless is stopped.
	WIFI_MODULE_UNLOAD_ENABLE=yes
	
	# Debugging can be set here or via commandline.
	#WIFI_DEBUG=-tdddd                                               
	
	# Whether to use nl80211
	#WIFI_80211=-Dnl80211
	
	end-of-wifi-configuration-file-block
fi
source $WIFI_CONFIG
    
if [ ! -x /sbin/wireless ]
then
  # ensure available as system command
  ln -sf /etc/network/wireless.sh /sbin/wireless
fi


# set debug mode from commandline, overrides conf
[ "${1:0:1}" == "-" ] && WIFI_DEBUG=${1} && shift
[ -z "${WIFI_DEBUG:1}" ] && WIFI_DEBUG= || echo 6 >/proc/sys/kernel/printk

# optionally, do not have to wait for a link
[ "$2" == "wait" ] && wfl=true || wfl=false

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
    # show dhd module
    lsmod |grep '^[Md][oh][d]'
    grep -q ath6k /proc/modules || echo "  ...not loaded" 
    # show if supplicant running
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
    ;;
    
  conf*)
    cat $WIFI_CONFIG
    ;;
    
  log)
    cat $WIFI_LOG
    ;;
    
  *)
    module=`ls -l $WIFI_MODULE |grep -o '[^ /]*$'`
    echo "$0"
    echo "Sets up the wireless $module driver and configures support for it."
    echo "Reads $WIFI_CONFIG.  (regenerated w/defaults, if missing)"
    echo 
    echo "AP association is governed by the 'sdc_cli' and an active profile."
    echo "External calls to this script can wait on it."
    echo "   (to avoid waiting for association, on start|restart, use 'nowait')"
    echo
    echo "Usage:"
    echo "# ${0##*/} [<-tdd...>] {start|stop|restart|status|conf|log} [{wait}]"
    exit 1
    ;;
esac
