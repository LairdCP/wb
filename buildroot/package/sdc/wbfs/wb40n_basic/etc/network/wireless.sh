#!/bin/sh
# /etc/network/wireless.sh - driver-&-firmware configuration
# Supports the Broadcom Dongle Host Driver. 
# ksjonh_20120520
#
trap "" 1 15
WIFI_CFG=/etc/summit/wifi_interface.conf

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
  cn=0
  while [ $cn -lt $1 ]
  do
    link=$( cat /sys/class/net/$WIFI_ETH/wireless/link 2>/dev/null )
    [ -n "$link" ] && [ $link -gt 0 ] && break
    #
    sleep 1
    cn_='\033[1K\r'
    let cn+=1 && msg -en .
    let sn=$cn%11
    if [ $sn -eq 0 ]
    then
      ps |grep -q sup[p] \
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
  msg "  ...checking $WIFI_ETH"
  let x=0
  while [ $x -lt $1 ]
  do
    grep -q $WIFI_ETH /proc/net/dev && break
    busybox usleep 10000 && let x+=1 && msg -en .
  done
  [ $x -gt 0 ] && msg
  [ $x -ge $1 ] && return 1 || return 0
}

wifi_queryinterface()
{
  WIFI_ETH=`sed -n "s/^device \(.*\):.*/\1/p" $WIFI_LOG 2>/dev/null`
  [ -n "$WIFI_ETH" ] \
  || WIFI_ETH=`dmesg -f kern |grep "$WIFI_DEVICE"`
  ##
  WIFI_ETH=${WIFI_ETH%%:*}
}

wifi_start()
{
  echo -n >$WIFI_LOG
  grep -q dhd /proc/modules && {
    wifi_queryinterface
  } || {
    ## Note: The pre-existence of the profiles.conf file is mandatory!!!
    # Simply calling the sdc_cli will regenerate the profiles.conf file.
    # If it is regenerated while the driver is loaded, trouble awaits...
    [ -f /etc/summit/profiles.conf ] \
    || { msg "re-generating /etc/summit/profiles.conf"; sdc_cli quit; }
    
    # make sure these modules are loaded, dhd needs them 
    modprobe mmc_core
    modprobe at91_mci

    ## load driver using interface prefix
    msg -en "loading `ls -l $WIFI_DRIVER |grep -o '[^ /]*$'`"
    [ -n "$driver_load_fw" ] && echo -en " +fw"
    [ -n "$driver_load_nv" ] && echo -en " +nv"
    #
    eval \
    insmod $WIFI_DRIVER iface_name=$WIFI_PREFIX $driver_load_fw $driver_load_nv \
    && msg || { msg "  ...driver failed to load"; exit 1; }

    ## enumerated interface should be available upon load
    WIFI_ETH=`dmesg -f kern |grep "$WIFI_DEVICE"`
    echo "device $WIFI_ETH" >>$WIFI_LOG
    WIFI_ETH=${WIFI_ETH%%:*}
    [ -z "$WIFI_ETH" ] \
    && { msg "  ...driver init failed, aborted"; exit 1; }

    ## wait some (10*mSec) for interface to be ready
    wifi_checkinterface 67 \
    && { msg "  ...driver loaded, interface $WIFI_ETH available"; } \
    || { echo "  ...error, interface $WIFI_ETH is not available/usable"; exit 1; }
    
    ## employ dhd utility to load firmware and nvram, if not via driver
    if [ "${WIFI_USE_DHD_TO_LOAD_FW:0:1}" == "y" ]
    then
      echo "loading fw: `ls -l $WIFI_FIRMWARE |grep -o '[^ /]*$'`"
      dhd -i $WIFI_ETH download $WIFI_FIRMWARE $WIFI_NVRAM || exit 1
    fi
  }  

  # try to enable interface  
  msg "activating $WIFI_ETH"
  [ -n "$WIFI_ETH" ] && /sbin/ifconfig $WIFI_ETH up 2>>$WIFI_LOG \
  || { msg "dev $WIFI_ETH n/a, maybe fw issue, try: wireless restart"; exit 1; }

  # legacy activation method
  [ "${WIFI_ACTIVATE_SETTINGS:0:1}" == "y" ] \
  && printf "activate_global_settings\nactivate_current\n" |/usr/bin/sdc_cli

  # save MAC address for WIFI if necessary
  if [ -z "$WIFI_MACADDR" ]
  then
    #WIFI_MACADDR=`/sbin/ifconfig $WIFI_ETH |sed -n 's/.*HWaddr \(.*\)/\1/p'`
    WIFI_MACADDR=`cat /sys/class/net/$WIFI_ETH/address 2>/dev/null`
    if grep -q ^WIFI_MACADDR $WIFI_CFG
    then
      sed "s/^WIFI_MACADDR.*/WIFI_MACADDR=$WIFI_MACADDR/g" -i $WIFI_CFG
    else
      echo -e "\nWIFI_MACADDR=${WIFI_MACADDR}\n" >>$WIFI_CFG
    fi
  fi

  # launch supplicant as daemon if not running
  if ! ps |grep -q sdcsup[p]
  then
    msg "launching supplicant"
    /usr/bin/sdcsupp $WIFI_DEBUG -i $WIFI_ETH >>$WIFI_LOG 2>&1 &
  fi
}

wifi_stop() {
  if [ -n "$WIFI_ETH" ] \
  && grep -q $WIFI_ETH /proc/net/dev
  then
    msg "deconfiguring $WIFI_ETH"
    ifconfig $WIFI_ETH 0.0.0.0
    #
    f='\ \ *\([^ ][^ ]*\)'
    for pid in \
    $( ps |sed -n "/sed/d/$WIFI_ETH/s/^\ *\([0-9]*\)${f}${f} [^ ].*$/\1=\3/p" )
    do
      [ $PPID -eq ${pid%%=*} ] && { msg "$pid ...skipping"; continue; }
      kill $k9 ${pid%%=*} \
      && msg `printf "%5d %s terminated\n" ${pid%%=*} ${pid##*=}`
      # have to kill off anything using interface or it won't be a clean stop
    done
    msg "disabling $WIFI_ETH ..."
    /usr/bin/sdc_cli disable >/dev/null 2>&1
  fi
  if [ "${WIFI_DRIVER_UNLOAD_ENABLE:0:1}" == "y" ] \
  && grep -q dhd /proc/modules
  then
    msg -en "unloading dhd driver"; /sbin/rmmod dhd
  fi
  [ $? ] && { msg "  ...okay"; return 0; } || { msg "  ...error"; return 1; }
}

#
# config files location
# ensure that the config file has the following 5-items set
#[ "5" != "`grep -cEs '_PREFIX=|_DEVICE=|_DRIVER=|_LOG=|_TIMEOUT=' $WIFI_CFG`" ]
if [ ! -f $WIFI_CFG ]
then
  echo "re-generating $WIFI_CFG"
  cat >$WIFI_CFG<<-	end-of-wifi-configuration-file-block
	# $WIFI_CFG                                                           

	# The interface name is enumerated from the following prefix.
	WIFI_PREFIX=eth
	WIFI_INTERFACE_NAME=

	# Autoprobed if not specified.
	WIFI_MACADDR=

	# Description of wireless device, will appear in dmesg.
	WIFI_DEVICE="Broadcom Dongle"
	
	# Location and name of log file.                                         
	WIFI_LOG=/var/log/wireless

	# Timeout for association in seconds.
	WIFI_TIMEOUT=60

	# The kernel driver to load. (can be a symlink)
	WIFI_DRIVER="/lib/modules/\`uname -r\`/extra/drivers/net/wireless/dhd.ko"
	WIFI_FIRMWARE=/etc/summit/firmware/fw
	#WIFI_FIRMWARE=/etc/summit/firmware/4329b1-4-220-55-sdio-ag-cdc-roml-reclaim-11n-wme-minccx-extsup-aoe-pktfilter-keepalive.bin
	WIFI_NVRAM=/etc/summit/nvram/nv
	
	# Whether the driver should be unloaded when wireless is stopped.
	WIFI_DRIVER_UNLOAD_ENABLE=yes
	#WIFI_USE_DHD_TO_LOAD_FW=yes
	
	#WIFI_ACTIVATE_SETTINGS=yes
	
	#WIFI_DEBUG=-tdddd                                               

	end-of-wifi-configuration-file-block
fi

#
source $WIFI_CFG || { echo "conf error"; exit 1; }
# set method of loading firmware and nvram
if [ "${WIFI_USE_DHD_TO_LOAD_FW:0:1}" != "y" ]
then
  driver_load_nv=nvram_path=$WIFI_NVRAM
  driver_load_fw=firmware_path=$WIFI_FIRMWARE
fi
    
if [ ! -x /sbin/wireless ]
then
  # ensure available as system command
  ln -sf /etc/network/wireless.sh /sbin/wireless
fi


# set debug mode from commandline, overrides conf
[ "${1:0:1}" == "-" ] && WIFI_DEBUG=${1} && shift
[ -z "${WIFI_DEBUG:1}" ] && WIFI_DEBUG= || echo 6 >/proc/sys/kernel/printk

# optionally, do not have to wait for a link
[ "$2" == "nowait" ] && wfl=false || wfl=true

case "$1" in
  
  stop|down)
    wifi_queryinterface
    echo \ \ Stopping wireless $WIFI_ETH
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
    lsmod |grep "^[Md][oh][d]"
    grep -q dhd /proc/modules || echo "  ...not loaded" 
    # show if supplicant running
    echo -e "\nSupplicant:"
    ps -o pid,args |grep sup[p] || echo "  ...not running"
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
    cat $WIFI_CFG
    ;;
    
  log)
    cat $WIFI_LOG
    ;;
    
  *)
    module=`ls -l $WIFI_DRIVER |grep -o '[^ /]*$'`
    echo "$0"
    echo "Sets up the wireless $module driver and configures support for it."
    echo "Reads $WIFI_CFG.  (regenerated w/defaults, if missing)"
    echo 
    echo "AP association is governed by the 'sdc_cli' and an active profile."
    echo "External calls to this script can wait on it."
    echo "   (to avoid waiting for association, on start|restart, use 'nowait')"
    echo
    echo "Usage:"
    echo "# ${0##*/} [<-tdd...>] {start|stop|restart|status|conf|log} [{nowait}]"
    exit 1
    ;;
esac
