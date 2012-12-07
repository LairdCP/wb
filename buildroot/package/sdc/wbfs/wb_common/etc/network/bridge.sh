#!/bin/sh
# /etc/network/bridge.sh - starts and stops bridge mode
# This script relies on ifrc.sh for configuration work and the /e/n/i file.
# jon.hefling@lairdtech.com

#trap "" 1 15
#xc=\\033[1K\\\r
eni=/etc/network/interfaces

[ -x /usr/sbin/brctl ] || { echo "brctl n/a"; exit 1; }
[ -x /sbin/ebtables ] || { echo "ebtables n/a"; exit 1; }
[ -x /sbin/ifrc ] || { echo "ifrc n/a"; exit 1; }

# defaults in lieu of a bridge_settings from cli or from /e/n/i file
bridge_device="br0"
bridge_ports="eth0 eth1"
bridge_setfd="0"
bridge_stp="off"
bridge_method="dhcp"

#echo " <> $0 $@"
# arg1 is bridge_device name

start() {
  echo Starting bridged network support.

  for dev in $bridge_ports; do ifrc $dev start manual || exit 1; done

  brctl addbr $bridge_device
  brctl stp $bridge_device $bridge_stp
  brctl setfd $bridge_device $bridge_setfd
  brctl addif $bridge_device $bridge_ports
  
  echo \ \ enablng $bridge_device
  if [ -n "$dev" ] \
  && ifrc $bridge_device up manual 
  then
    #modprobe nf_conntrack_ipv4
    echo 1 > /proc/sys/net/ipv4/conf/all/proxy_arp
    echo 1 > /proc/sys/net/ipv4/ip_forward
    ebtables -t nat -F PREROUTING
    ebtables -t nat -F POSTROUTING
    ebtables -t broute -F BROUTING
    ebtables -t nat -A PREROUTING  --in-interface $dev -j arpnat --arpnat-target ACCEPT
    ebtables -t nat -A POSTROUTING --out-interface $dev -j arpnat --arpnat-target ACCEPT
    ebtables -t broute -A BROUTING --in-interface $dev --protocol 0x888e -j DROP
    [ "$bridge_method" != "manual" ] \
    && ifrc $bridge_device up $bridge_method
  else
    echo \ \ bridge setup failed; exit 1
  fi
  brctl show
}

stop() {
  echo Stopping bridged network support.
  ebtables -t nat -F
  ebtables -F
  echo 0 > /proc/sys/net/ipv4/conf/all/proxy_arp
  echo 0 > /proc/sys/net/ipv4/ip_forward
  
  echo \ \ disabling $bridge_device 
  ifconfig $bridge_device down 2>/dev/null
  
  # delete bridge name if it exists
  brctl show |grep -q $bridge_device \
  && { echo -en \ \ ; brctl delbr $bridge_device && echo done; }
}



# optional -x is no-wait-on-network-script 
[ "$1" == "-x" ] && nwons=false && shift || nwons=true

# take subsequent parameters as args for bridge device and settings
cmd=$1 && shift

# expecting next arg to be bridge_device name, this is optional
if [ -n "$1" ]
then
  bridge_device=$1 && shift
fi

# look for passed-in settings or read from /e/n/i
if [ -n "$1" ] \
&& [ "${1%%_*}" == "bridge" ]
then
  bridge_settings="$@"
else
  eval `sed -n "s/^iface \(br[i0-9][dge]*\) inet \([a-z]*\)/\
     bridge_device=\1 bridge_method=\2/p" $eni 2>/dev/null`

  [ -n "$bridge_device" ] \
  && bridge_settings=$( sed -n "/^iface $bridge_device inet/,/^$/\
     s/^[ \t][ ]*\(bridge_[a-z]*\)[ ]\(.*\)/\1=\"\2\"/p" $eni 2>/dev/null )
fi
if [ -n "$bridge_settings" ]
then
  #echo \ \ eval $bridge_settings
  eval $bridge_settings
fi

case $cmd in
  stop)
    stop
    ;;

  start)
    start
    ;;

  restart)
    stop
    start
    ;;

  *)
    echo "Usage: $0 {stop|start|restart} [<bridge_settings...>]"
    exit 1
    ;;
esac
exit 0

