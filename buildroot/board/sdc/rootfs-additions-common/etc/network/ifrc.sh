#!/usr/bin/env ash
# /etc/network/ifrc.sh - interface_run_config
# A run-config/wrapper script to operate on kernel-resident network interfaces.
# Provides auto-reconfiguration via netlink support.
# ksjonh_20120520
#
usage()
{
  rv=0
  [ "${1:0:5}" == "error" ] \
  && { echo -e "${2:+# $2\n}${3:+# $3\n}#"; rv=1; sleep 3; }
  cat <<-	\
	usage-info-block
	$( echo -e "\t\t\t\t\t\t\t  (interface-run-config)\r\c"; \
	                                 ls -l $0 |grep -o "$0.*" )
	Configure and/or show network interfaces.
	Use settings in '/etc/network/interfaces', or from the command-line.
	Works with a netlink daemon to maintain dhcp/static methods on-the-fly.
	
	Flags:
	  -h   this helpful summary
	  -q   be quiet, no stdout
	  -v   be more verbose...
	  -m   monitor ifrc events
	  -n   no logging to files
	  -r   remove the log files
	  -x   run w/o netlink daemon
	     ( Note:  ifrc may be disabled with:  /etc/default/ifrc.disable )
  
	Interface:
	  must be kernel-resident of course
	  can be an alias (such as 'wl' for wireless, see /e/n/i file)

	Action:
	  stop|start|restart   - act on phy-init/driver (up or down the hw-phy)
	  auto|noauto   - set or unset auto-starting an interface (for init/rcS)
	  status   - check an interface and report its ip-address, with exit code
	  up|dn   - up or down the interface configuration (use '...' to renew)
	  show   - specific interface info, or general info (default)
	  eni   - edit file: /etc/network/interfaces
	  help   - view file: /etc/network/networking.README

	Method:
	  dhcp [<param=value> ...]
	     - employ client to get/renew lease, info stored in leases file
	       address=x.x.x.x   - request an ip address from dhcp server
	       timeout=nn   - seconds to allow client to try/await response
	       $mii_speed

	  static [<param=x.x.x.x[\nn]> ...]
	     - use settings from /e/n/i file or those given on commandline
	       params:  address, netmask, broadcast, gateway  (ip,nm,bc,gw)

	  loopback [<param=value>]
	     - use to set a specific localhost address
	
	  manual
	     - the interface will not be configured

	Usage:
	# ifrc [flags...] [<interface>] [<action>] [<method> [<param=value> ...]]
	#
	usage-info-block
  #
  exit $rv
}

msg()
{
  if [ "$1" == "@." ] && shift
  then
    # to console w/'@.' prefix in monitor-mode
    [ -n "$mm" ] && echo -e "$@" >/dev/console
  else
    # to stdout while not quiet-mode
    [ -z "$qm" ] && echo -e "$@" || :
  fi
  # and log unless set to /dev/null
  echo -e "$@" >>$ifrc_Log || :
}


# internals
ifrc_Disable=/etc/default/ifrc.disable
ifrc_Version=20130203
ifrc_Script=/etc/network/ifrc.sh
ifrc_Time= #$( date +%s.%N )
ifrc_Log=/var/log/ifrc
ifrc_Cmd="$0 $@"
ifrc_Via=
ifrc_Pid=$$

eni=/etc/network/interfaces

# check mii (optional)
mii=/usr/sbin/mii-diag
if [ ! -x "$mii" ]
then
  mii=
else
  # this package is used to optionally set a fixed port speed during dhcp
  mii_speed="portspeed=10baseT...   - use fixed port speed during dhcp trial"
fi

# check ifrc
ifrc=/sbin/ifrc
if [ ! -x "$ifrc" ]
then
  # link as system command
  ln -sf $ifrc_Script $ifrc
fi

# check ifplugd - testing
#ifplugd=/usr/bin/ifplugd
#ifplugd=/root/busybox\ ifplugd

parse_flag()
{
  case $1 in
    \?|-h|--help) ## show usage
      usage
      ;;
    --) ## just report version
      msg ${ifrc_Script##*/} $ifrc_Version
      exit 0
      ;;
    -r) ## remove all related ifrc log files on startup
      for f in /var/log/ifrc*; do rm -f $f && msg ${f##*/} log removed; done
      let $#-1  && return 1 || exit 0
      return 1
      ;;
    -n) ## do not use a log file
      ifrc_Log=/dev/null
      ;;
    -q) ## quiet, no stdout
      qm='>/dev/null'
      ;;
    -v) ## add verbosity, multi-level
      vm=$vm.
      ;;
    -x) ## do not run netlink daemon
      ifnl_disable=.
      ;;
    -m) ## monitor nl/ifrc events for a specific iface
      mm=@
      ;;
    -*) ## ignore
      msg \ \ ...ignoring $1
      return 1
      ;;
  esac
  return 0
}
while [ "${1/[\?-]*/%}" == "%" ]; do parse_flag $@ && fls=$1\ $fls; shift; done

# latch settings
eval $ifrc_Settings
export ifrc_Settings=fls=\"$fls\"\ mm=$mm\ vm=$vm\ qm=$qm  

# set some message levels according to verbose-mode
[ -n "${vm:2:1}" ] && alias msg3=msg || alias msg3=:                           
[ -n "${vm:1:1}" ] && alias msg2=msg || alias msg2=:                           
[ -n "${vm:0:1}" ] && alias msg1=msg || alias msg1=:                           
[ -z "${qm:0:1}" ] && alias msg0=msg || alias msg0=:

# don't run ifrc if the 'disable' flag-file exists
[ -f "$ifrc_Disable" ] && { msg1 "  $ifrc_Disable exists..."; exit 0; }

# set ifnl_s when called via netlink daemon
ifnl_s=${IFPLUGD_PREVIOUS}-\>${IFPLUGD_CURRENT}
ifnl_s=${ifnl_s//error/xx}
ifnl_s=${ifnl_s//down/dn}
[ "$ifnl_s" == "->" ] && ifnl_s=

[ -n "$rcS_" ] && ifrc_Via=" (...via rcS)"
[ -n "$ifnl_s" ] && ifrc_Via=" (...via ifplugd)"
[ -n "$ifrc_Via" ] && qm='>/dev/null'

[ "$vm" == "....." ] && set -x



sleuth_wl()
{
  # try to find kernel-resident (wireless) interface: wl
  # in this case, it is not certain what the name is ahead of time
  for x in /sys/class/net/*/wireless
  do
    x=${x##*/sys/class/net/}; x=${x%%/*}; [ "$x" != \* ] && { echo $x; break; }
  done
}

show_bridge_mode()
{
  bridge_info()
  {
    [ 3 -eq $# ] \
    && echo -e "Bridge mode interface '$1' active using '$2' and '$3'.\n"
  }
  if ps |grep -q 'S[0-9][0-9]bridge.*start'
  then
    echo -e "Bridge mode setting up...\n"
  else
    if grep -q 'br[0-9]' /proc/net/dev
    then
      bmi=$( brctl show |sed -n '2{p;n;p;}' |grep -o '[a-z][a-z][a-z]*[0-9]' )
      bridge_info $bmi
    fi
  fi
}

show_interface_config_and_status()
{
  ida=$( ifconfig -a |sed -n '/./{H;$!d;};x;/\ UP/!p' \
                     |sed -n 's/\(^[a-z][a-z0-9]*\).*/\1 /p' \
                     |tr -d '\n' )

  [ -z "$dev" -a -n "$ida" ] \
  && echo "       Available, but not configured: $ida"
  echo
  ifconfig |sed -n "/${dev}/,/^$/p" \
           |sed '/packe/d; /queue/d; /nterr/d; /cope/d' \
           |sed 's/^\(.......\)\ *\([^ ].*[^ ]\)\ */\1\2/g; s/0-0/0:0/g; $d' \
           |grep ....... || return 1

  [ -n "$dev" ] || dev=$( sleuth_wl )
  # include association info for wireless dev
  if [ -n "$dev" ] \
  && grep -q $dev /proc/net/wireless 2>/dev/null
  then
    wlstat=$( ps -o args \
            |sed -n 's/.*[w]ireless.*\([uds].*\)/initializing - \1/p' )
    echo -e "\nWiFi:\t$wlstat"
    #iwconfig 2>/dev/null
    iw dev $dev link 2>/dev/null \
      |sed "s/^Connec/Associa/;s/t connec.*/t associated (on $dev)/" \
      |sed "s/^\t/              /"
  
    # too slow
    #sdc_cli profile list |sed -n 's/\(.*\) ACTIVE/WiFi profile: \1/p'
  # top -n 1 |grep -E 'COMMAND|supp|wire|dhd' |grep -v grep
  fi
  return 0
}

ifrc_stop_netlink_daemon()
{
  prg="ifplug[d]"
  # find all ifplug* instances for this interface  
  for pid in \
  $( ps |sed -n "/${dev}/s/^[ ]*\([0-9]*\).*[\/ ]\(${prg}\)[ -].*/\1_\2 /p" )
  do
    kill ${pid%%_*} \
    && msg @. "`printf \"% 7d %s <-sigterm\" ${pid%%_*} ${pid##*_}`"
  done
}

signal_dhcp_client()
{
  case $1 in
    USR1) action=sigusr1; signal=-10;;
    TERM) action=sigterm; signal=-15;;
    CONT) action=sigcont; signal=-18;;
  esac

  let rv=1
  prg="[u]*dhc[lp][ic][dent3]*"
  # find all possible client instances for this interface
  # (including: udhcpc, dhclient, dhcpcd, dhcp3-client)
  for pid in \
  $( ps |sed -n "/${dev}/s/^[ ]*\([0-9]*\).*[\/ ]\(${prg}\)[ -].*/\1_\2 /p" )
  do
    if kill $signal ${pid%%_*}
    then
      msg @. "`printf \"% 7d %s <-${action}\" ${pid%%_*} ${pid##*_}`"
      let rv=0
    else
      let rv=1
    fi
  done

  # interrupt link-beat check, if in-progress
  [ -f /tmp/ifrc.$dev.lbto ] \
  && rm -f /tmp/ifrc.$dev.lbto && usleep 199999

  return $rv
}

make_dhcp_renew_request()
{
  for x in 1 2 3 4 5
  do
    msg1 \\\trenew_req: $x
    { read -r txp_a </sys/class/net/$dev/statistics/tx_packets; } 2>/dev/null
    signal_dhcp_client USR1 && usleep 666666 || break
    let txp_b=$txp_a
    { read -r txp_a </sys/class/net/$dev/statistics/tx_packets; } 2>/dev/null
    msg2 \\\ttx_packets: $txp_a-$txp_b
    let $txp_a-$txp_b && return 0
  done
  msg1 \\\tfailed...
  return 1
}


[ -n "$ifnl_s" ] \
&& msg2 @. ifnl_s/args_: "$ifnl_s" $@

# 
# the 1st arg should be an interface dev name
# however, some actionable exceptions can be handled before qualifing iface dev
case $1 in

  stop|start|restart) ## call network-init w/action-&-args, no return
    exec /etc/init.d/S??network* "" $1 $2
    ;;
  
  show|"") ## iface missing, and no other action, so show any/all
    echo "Configuration for all interfaces" \
         "                          (try -h to see usage)"
    if show_interface_config_and_status 
    then
      echo
      show_bridge_mode
      route -ne
      echo -e "\nDNS:\r\t/etc/resolv.conf"
      sed '$G' /etc/resolv.conf 2>/dev/null
    fi
    if [ -n "${vm:0:1}" ]
    then
      ps -o pid,args |grep -E 'dhc[pl]|ifplug[d]|wi[rf][ei]|sup[p]|ne[t]|br[i]'
    fi
    exit 0
    ;;

  help) ## view the readme file
    less -Em~ /etc/network/networking.README
    # NOTE - the EOF detection is not working in bb_1.3.19
    exit 0
    ;;

  eni) ## edit the /e/n/i file
    cp -f $eni /tmp/ifrc.${eni##*/}~
    if /bin/vi /tmp/ifrc.${eni##*/}~ \
    && ! cmp -s /tmp/ifrc.${eni##*/}~ $eni
    then
      let $( ls -s /tmp/ifrc.${eni##*/}~ |sed 's/\ *\([0-9]\+\).*/\1/' )+0 \
      && mv -f /tmp/ifrc.${eni##*/}~ $eni \
      || echo "unable to copy edited $eni into place"
    fi
    exit 0
    ;;  

  noauto|auto|flags|status|down|dn|up) ## require iface
    usage error: "...missing interface" "ifrc <iface> $1" 
    ## maybe use 'status' w/o dev to show system load...
    ;;

  #xx*|--*|\.\.*)
  #  ;;

  [a-z][a-z]*)
    dev=$1 && shift
    ;;

  *) usage error: "invalid interface name";;
esac


#
# For operations herein, we generally act on the $dev.
# It is possible that the $dev may initially be unknown.
# So, for /e/n/i file lookups, we assume the use of $devalias.
#
if [ ! -f $eni ]
then
  # Without having the /e/n/i file, then given interface and settings must be
  # explicitly provided.  Although, method 'dhcp' will be ultimately assumed.
  #
  # Handle some dev name exceptions here first.
  [ "$dev" == "wl" ] \
  && devalias=$( sleuth_wl )
elif [ -n "$dev" ]
then
  # See if this is an aliased interface to act on...
  # otherwise we treat the interface (and assume) as an alias by the same name.
  # when given dev is the alias for an interface name, determine actual name
  # when given dev is the actual interface name of an alias, copy as alias
  D='[a-z][a-z][a-z0-9]*'
  msg3 "  checking the /e/n/i file to determine if aliased interface"
  devalias=$( sed -n "/$dev/s/^[ \t]*alias \($D\)[ is]* \($D\)/\1 \2/p" $eni )
  msg3 "  eni_alias: ${devalias%% *}?${devalias##* }"
  deviface=$( sed -n "/$dev/s/^iface $dev.*/$dev/p" $eni )
  msg3 "  eni_iface: $deviface?"
  ##
  if [ -z "$devalias" ]
  then
    if [ -n "$deviface" ]
    then
      [ "$dev" == "wl" ] \
      && devalias=$( sleuth_wl ) \
      || devalias=$dev
    else  
      devalias=$dev
      msg3 "  ...no alias found, so assumed to be real"
    fi
  else
    # found alias, so try to sort out what is the actual name...
    if [ "${devalias%% *}" != "$dev" ]
    then
      ifacemsg="(alias)"
      dev=${devalias##* }
      devalias=${devalias%% *}
      msg3 "  ...\"${devalias}\" is the alias for \"${dev}\""
    elif [ "${devalias##* }" != "$dev" ]
    then
      ifacemsg="(alias)"
      dev=${devalias##* }
      devalias=${devalias%% *}
      msg3 "  ...assumming \"${dev}\" as \"${devalias}\""
    else
      devalias=$dev
      msg3 "  ...can't determine, so assuming $dev"
    fi
  fi
  
  ##
  # check for ifrc-options
  IFRC_flags=$( sed -n "/^iface $devalias/,/^$/\
                s/^[ \t]\+[^#]ifrc-flags \(.*\)/\1/p" $eni 2>/dev/null )
  #
  [ -n "$IFRC_flags" ] \
  && msg3 "applying ifrc-flags via /e/n/i: $IFRC_flags"
  for af in $IFRC_flags; do parse_flag $af; done

  ##
  # check for ifrc-pre/post-do scripts
  if [ -z "$IFRC_SCRIPT" -a -n "$devalias" ]
  then
   msg3 "parsing /e/n/i for pre/post commands, intended for $dev..."
   IFRC_SCRIPT=$( sed -n "/^iface $devalias/,/^$/\
      s/^[ \t][ ]*\([^#]p[or][se][t]*\)-\([d]*cfg\)-do \(.*\)/\1_\2_do='\3'/p"\
      $eni 2>/dev/null )
    #
    eval $IFRC_SCRIPT
  fi
fi


#
# Extended operations, intended for a specific interface...
#
[ -n "$dev" ] || exit 1

# set logfile name
# limit the file size to just 100-blocks
if [ "$ifrc_Log" != "/dev/null" ]
then
  ifrc_Log=${dev:+$ifrc_Log.$dev}
  let sz=$( ls -s $ifrc_Log 2>/dev/null |sed 's/\ *\([0-9]\+\).*/\1/' )+0
  [ $sz -gt 100 ] && ifrc_Log=/dev/null
fi

# begin a new log entry for the operations that follow 
echo -e "\n`date +'%b %e %H:%M:%S'` __${ifrc_Cmd}  $ifrc_Via" >>$ifrc_Log
msg3 "` env |sed -n 's/^IF[A-Z]*_.*/  &/p' |sort`"

# external globals - these can be used by *-cfg-do scripts
export IFRC_STATUS="${ifnl_s:-  ->  }"
export IFRC_DEVICE=$dev
export IFRC_ACTION
export IFRC_METHOD
export IFRC_METHOD_PARAMS
export IFRC_SCRIPT

# determine action to apply
if [ -z "$1" ]
then
  # no action arg, so assume 'show'
  IFRC_ACTION=show
else
  # an action arg and maybe params, passed in...
  IFRC_ACTION=$1 && shift
  if [ -n "$1" ]
  then
    methvia="(set via cli)"
    IFRC_METHOD=$1 && shift
    IFRC_METHOD_PARAMS="$@"
  fi
fi

# determine method to apply
if [ "$IFRC_ACTION" == "up" ]
then
  ## assume method and params if not specified
  if [ -z "$IFRC_METHOD" ]
  then
    msg3 "determining method for... $devalias"
    IFRC_METHOD_PARAMS=""
    if [ -f $eni ]
    then
      IFRC_METHOD=$( sed -n "s/^iface $devalias inet \([a-z]*\)/\1/p" $eni )
      [ "$IFRC_METHOD" == "static" ] \
      && IFRC_METHOD_PARAMS=$( sed -n "/^iface $devalias inet $IFRC_METHOD/,/^$/s/^[ \t][ ]*\([^#][a-z]*\)[ ]\(.*\)/\1=\2/p" $eni )
    fi
    if [ -n "$IFRC_METHOD" ]
    then
      methvia="(via /e/n/i)"
    else
      methvia="(assummed)"
      IFRC_METHOD="dhcp"
      IFRC_METHOD_PARAMS=""
    fi
  fi  
fi  

# determine netlink rule to apply
if [ -n "$ifnl_s" ]
then
  ## run via nl daemon, so consume remaining args
  # Currently no defined need for (optional) extra args...
  while [ -n "$ifnl_s" -a -n "$1" ]; do shift; done
  
  ## event rules for '->dn'
  if [ "${IFRC_STATUS##*->}" == "dn" ]
  then
    if [ ! -f /sys/class/net/$dev/carrier ]
    then
      msg1 $dev is gone, waiting 2s
      sleep 2
      if [ ! -f /sys/class/net/$dev/carrier ]
      then
        msg1 $dev is gone, so allowing deconfiguration
        IFRC_ACTION=dn
      else
        msg 1 ignoring down event for dhcp method - iface is back
        IFRC_ACTION=xxx
      fi
    else
      if [ "$IFRC_METHOD" == "dhcp" ]
      then
        msg1 ignoring down event for dhcp method
        IFRC_ACTION=xxx
      fi
    fi
  fi
  
  ## event rules for current '->up'
  if [ "${IFRC_STATUS##*->}" == "up" ]
  then
    if [ "$IFRC_METHOD" == "dhcp" ]
    then
      # check if dhcp client is running
      signal_dhcp_client CONT && IFRC_ACTION=...
    fi
  fi

  ##
  ## additional rules can handle other condition/states here...
  ##
fi

msg @. ifrc_s/d/a/m: "$IFRC_STATUS" $IFRC_DEVICE ${IFRC_ACTION:-.} $IFRC_METHOD
#
# Do not really 'down' or 'up' an interface here with: 'ifconfig <dev> down/up'
# We leave that to the init/driver scripts instead, so they handle stop/start.
#
# This script uses down/up with respect to interface (de)configuration only!!
#
case $IFRC_ACTION in
  status) ## check if iface is configured and show its ip-address
    ## confirm configured <iface>: [ip-address]:0/1
    ip=$( ifconfig $dev 2>/dev/null |sed -n 's/\ *inet addr:\([0-9.]*\) .*/\1/p' )
    [ -n "$ip" ] && { msg $ip; exit 0; } || exit 1
    ;;

  show) ## show info/status for an iface
    if ! grep -q $dev /proc/net/dev
    then
      echo -e "\t$dev ...not available, not a kernel-resident interface"
      exit 1
    fi
    #if [ "$devalias" != "wl" ]
    #then
      # summarize the status of this interface
      { read -r ccl </sys/class/net/$dev/carrier; } 2>/dev/null
      [ "$ccl" != "1" ] && ccl="no carrier/cable/link" || ccl="linked"

      iw dev $dev link |grep -q Connected \
      && ccl="$ccl, associated"

      ps |grep -q "ifplug[d].*${dev}" && ccl="managed, $ccl" 

      ifconfig $dev |grep -q UP && ccl="$ccl, up" || ccl="$ccl, dn"

      if [ ! -f /sys/class/net/$dev/uevent ] \
      || grep -q Generic /sys/class/net/$dev/*/uevent 2>/dev/null
      then
        ccl="no interface-phy"
      fi
    #fi
    echo -e "Configuration for interface: $devalias $ifacemsg ...$ccl"
    show_interface_config_and_status
    #netstat -nre |grep -E "Kernel|Destina|$dev"
    #route -ne |grep -E "Kernel|Destina|$dev"
    if [ "$dev" == "lo" ]
    then
      echo -e "\nRouting: (local)"
      ip route show table local |grep "dev $dev"
    else
      echo -e "\nRouting:"
      ip route show table local |grep "dev $dev"
      ip route show table main |grep "dev $dev"
      [ -n "`arp -ani $dev |sed '/No match/d; $='`" ] && x=cached || x=empty
      echo -e "\nARP:\r\t($x)" && arp -ani $dev |sed '/No match/d;/^$/d'
      #echo -e "\nDNS:\r\t/etc/resolv.conf"
      #cat /etc/resolv.conf 2>/dev/null
    fi
    [ -n "${vm:0:1}" ] \
    && ps -o pid,args |grep -E 'dhc[pl]|ifplug[d]' |grep "$dev"
    echo
    exit 0
    ;;

  flags) ## (re)set ifrc-flags for an iface
    msg "not implemented"
    exit 0
    ;;

  noauto) ## unset auto-starting for an iface
    if grep -q "auto $devalias$" $eni
    then
      sed "s/^auto $devalias$/#auto $devalias/" -i $eni
    else
      if grep -q "^iface $devalias inet" $eni
      then
        # insert the noauto just above stanza iface
        sed "/^iface $devalias inet/i#auto $devalias" -i $eni
      else
        echo "stanza for $devalias not found in $eni"
        exit 1
      fi
    fi
    exit 0
    ;;
    
  auto) ## set auto-starting for an iface
    if grep -q "auto $devalias$" $eni
    then
      sed "s/^#auto $devalias$/auto $devalias/" -i $eni
    else
      if grep -q "^iface $devalias inet" $eni
      then
        # insert the auto just above stanza iface
        sed "/^iface $devalias inet/iauto $devalias" -i $eni
      else
        echo "stanza for $devalias not found in $eni"
        exit 1
      fi
    fi
    exit 0
    ;;

  stop|start|restart) ## act on init/driver, does not return
    exec /etc/init.d/S??network* $devalias $IFRC_ACTION
    ;;

  dn|down) ## assume down action ->deconfigure
    if [ -n "$pre_dcfg_do" ]
    then
      msg "   pre_dcfg_do"
      ( eval $pre_dcfg_do )&
              pre_dcfg_do=
    fi
    rm -fv /var/log/ifrc.$dev.lock
    msg1 "deconfiguring $dev"
    #
    # terminate any other netlink/dhcp_client daemons and de-configure
    ifrc_stop_netlink_daemon 
    signal_dhcp_client TERM
    { read -r operstate </sys/class/net/$dev/operstate; } 2>/dev/null
    [ "$operstate" == "up" ] && ifconfig $dev 0.0.0.0 2>/dev/null
    ## this de-configure (flush) is only performed on an 'up' interface
    ##
    usleep 333333
    if [ -n "$post_dcfg_do" ]
    then
      msg "   post_dcfg_do"
      ( eval $post_dcfg_do )&
              post_dcfg_do=
    fi
    exit 0
    ;;

  up) ## assume up action ->reconfigure . . .
    if [ "$dev" != "lo" ] \
    && [ "$devalias" != "wl" ] \
    && ! grep -q $dev /proc/net/wireless 2>/dev/null
    then
      msg1 "checking wired phy-hw"
      # detection of wired conflicts w/others
      # the interface should be identified... (probably floating hw otherwise)
      if [ ! -f /sys/class/net/$dev/uevent ] \
      || grep -q Generic /sys/class/net/$dev/*/uevent 2>/dev/null
      then
        msg "  ...interface-phy-hw '$dev' is not available"
        exit 1
      fi
    fi
    if [ ! -f /sys/class/net/$dev/uevent ]
    then
      if [ ! -f /var/log/ifrc.$dev.lock ]
      then
        msg "interface is not kernel-resident, trying to start ..."
        touch /var/log/ifrc.$dev.lock
        exec /etc/init.d/S??network* $devalias start $IFRC_METHOD
      else
        msg "interface is not kernel-resident, try:  ifrc $dev start"
        exit 1
      fi
    fi
    rm -fv /var/log/ifrc.$dev.lock
    [ "${IFRC_STATUS%%->*}" == "up" ] && re=re- || re=
    msg1 "${re}configuring $dev using $IFRC_METHOD method $methvia"
    #
    # terminate any other netlink/dhcp_client daemons and de-configure
    [ -z "$ifnl_s" ] \
    && ifrc_stop_netlink_daemon 

    # this is a new method/request
    signal_dhcp_client TERM

    ifconfig $dev 0.0.0.0 2>/dev/null \
    || msg "  ...deconfig for up_action resulting in error, ignored"
    ## this de-configure (flush) will also re-'up' the interface...
    ## additional wait time may be required to be ready again
    ##
    ## operations continue below...
    ;;

  \.\.\.) ## try signaling the dhcp client
    if [ ! -f /var/log/ifrc.$dev.lock ]
    then
      touch /var/log/ifrc.$dev.lock
      ## request dhcp renewal, and check if was really carried out
      ## under some tested conditions, the signal may be ignored
      ## if client stalls/dies, then re-exec using 'up' action
      if ! make_dhcp_renew_request \
      && [ "${IFRC_STATUS##*->}" == "up" ]
      then
        msg @. \ \ ...exec ifrc $fls $dev up $IFRC_METHOD $IFRC_METHOD_PARMS
        rm -f /var/log/ifrc.$dev.lock
        eval exec ifrc $fls $dev up $IFRC_METHOD $IFRC_METHOD_PARMS
      fi
    else
      msg1 \ \ ...lock file exists, aborted
      exit 0
    fi
    rm -f /var/log/ifrc.$dev.lock
    exit 0
    ;;
    
  ''|xx*|\.*) ## no.. action
    exit 0
    ;;

  *) ## usage, does not return
    usage error: "invalid action specified"
    ;;
esac


#
# The rest of this script handles the configuration of an interface.
# And is run when called again manually, or via the netlink daemon.
# So, the first step is to ensure that netlink is active for <interface>.
#
# exceptions:
[ "$IFRC_METHOD" == "manual" ] && ifnl_disable=.
[ "$dev" == "lo" ] && ifnl_disable=.

if [ -n "$ifnl_disable" ]
then
  msg1 "  ...ifnl_disable"
  ifrc_stop_netlink_daemon
else
  ps \
    |grep -q "ifplug[d].*${dev}" \
    && msg "  ...ifplugd running" \
    || {
      [ -n "$ifplugd" ] && msg using alternate nl-daemon: $ifplugd
      [ -n "${vm:1:1}" ] && nsl= || nsl=-s
      msg2 "netlink support not active, starting ifplugd  "
      ##
      ## If ifrc.sh exits with non-zero status, then ifplugd will not daemonize.
      ## Only exit non-zero for permanent conditions that prevent configuration.
    ( ${ifplugd:-ifplugd} -i $dev -M $nsl -q -p -a -f -u 1 -d 1 -I -r $0 )&
      usleep 333333
      ##
      ## Directly spawning nl-daemon prevents catching error conditions.
 #    ${ifplugd:-ifplugd} -i $dev -M $nsl -q -p -a -f -d 3 -I -r $0
      #ps \
      #  |grep -q "ifplug[d].*${dev}" \
      #  || {
      #    echo -e "\t...ifplugd failed to daemonize" >>$ifrc_Log
      #    exit 0
      #  }
      #msg @. "`printf \"% 7d %s started\" $ifplugd_pid ifplugd`"
    }
fi


#
# NOTE:
# The script will exit with a zero value even if configuration is deferred.
# This is considered a valid state, and upon a netlink event, configuration
# is automatically re-attempted via the netlink daemon, such as:
# 1. wifi is not associated yet (handled by supplicant)
# 2. cable/link not present yet
#
# The script will exit with a non-zero value whenever a permanent condition will
# prevent configuration of the interface, such as:
# 1. invalid method specified
# 2. no hw-phy detectable
# 3. timeout was used
# 4. other errors
#
# Generally, it is unwise to try waiting on this script, as some actions are 
# going to be deferred, depending on conditions.  In caller to this script;
#
# ...a simple timed-loop test for "inet addr" can be made:
# $( if ifconfig <iface> 2>/dev/null |grep -q 'inet addr'; then true; fi )
#
# ...or use ifrc to check status:
# $( if ifrc <iface> status; then true; fi )
# 

show_filtered_method_params()
{
  #if [ "${1:0:2}" == ".." ]
  if [ -n "$1" ] 
  then
    if [ -n "$ip$nm$gw$bc$ns" ]
    then
      echo \ \ ip: $ip
      echo \ \ nm: $nm
      echo \ \ gw: $gw
      echo \ \ bc: $bc
      echo \ \ ns: $ns
    fi
  fi
  [ -n "$rip" ] && msg request-ip-address: $rip
}

ifrc_validate_loopback_method_params()
{
  # validate extra parameters for loopback method
  for x in $IFRC_METHOD_PARAMS
  do
    echo $x |grep -q "[ia][a-z]*=[0-9].*" \
    || { msg "ignoring invalid extra parameter: $x"; continue; }
    case $x in
      ip=*|address=*) ## specify ip to request from server
        ip=${x##*=}
        ;;
      *)
        msg "ignoring extra parameter: $x"
    esac
  done
}

ifrc_validate_static_method_params()
{
  # validate extra dotted-address parameters for static method
  for x in $IFRC_METHOD_PARAMS
  do
    echo $x |grep -q "[aingb][a-z]*=[0-9]*.[0-9]*.[0-9]*.[0-9]*[/0-9]*" \
    || { msg "ignoring invalid extra parameter: $x"; continue; }
    ##
    case $x in
      ip=*|address=*)
        ip=${x##*=}
        ;;
      nm=*|netmask=*)
        nm=${x##*=}
        ;;
      gw=*|gateway=*)
        gw=${x##*=}
        ;;
      bc=*|broadcast=*)
        bc=${x##*=}
        ;;
      ns=*|nameserver=*)
        ns="$ns ${x##*=}"
        ;;
      fpsd=*|portspeed=*)
        fpsd=${x##*=}
        ;;
      *)
        msg "ignoring extra parameter: $x"
    esac
  done
}

ifrc_validate_dhcp_method_params()
{
  # validate extra parameters for dhcp method
  # these are handled specifically by the employed client
  [ -n "$rcS_" -a -f /tmp/bootfile_ ] && rbf=bootfile
  for x in $IFRC_METHOD_PARAMS
  do
    echo $x |grep -q "[iats][a-z]*=[0-9].*" \
    || { msg "ignoring invalid extra parameter: $x"; continue; }
    case $x in
      ip=*|address=*) ## specify ip to request from server
        rip=${x##*=}
        ;;
      to=*|timeout=*) ## specify a minimum timeout of 4s
        to=${x##*=}
        [ 4 -le $to ] || let to=4
        ;;
      fpsd=*|portspeed=*) ## specify a fixed-port-speed-duplex to use for dhcp
        fpsd=${x##*=}
        ;;
      *)
        msg "ignoring extra parameter: $x"
    esac
  done
  ipa=
}

check_link()
{
  # check if associated when using wireless
  if grep -q $dev /proc/net/wireless 2>/dev/null
  then
    link=`sed -n "s/${dev}: [0-9]*[ ]*\([0-9]*\).*/\1/p" \
        /proc/net/wireless 2>/dev/null`

    let $link+0 \
    || { msg "  ...not associated, deferring"; exit 0; }
  fi

  # need a link beat in order for dhcp to work
  # so try waiting up to 30s, and then double check
  touch /tmp/ifrc.$dev.lbto
  let lbto=30000
  let n=0
  while [ $n -lt $lbto -a -f /tmp/ifrc.$dev.lbto ]
  do
    grep -q 1 /sys/class/net/${dev}/carrier && break
    usleep 200000 && let n+=200
  done
  rm -f /tmp/ifrc.$dev.lbto

  grep -q 1 /sys/class/net/${dev}/carrier \
  || { msg "  ...no carrier/cable/link, deferring"; exit 0; }

  [ $n -gt 0 ] && msg "  waited ${n}ms on ${dev}/carrier"
}

run_udhcpc()
{
  #source /etc/dhcp/udhcpc.conf 2>/dev/null
  
  # set no-verbose or verbose mode level
  [ -z "$vm" ] && nv='|grep -E "obtained|udhcpc"'
  [ "${vm:2:1}" == "." ] && vb='-v' 
  [ "${vm:1:1}" == "." ] && q=

  # optional exit-no-lease and quit
  nq=

  # optional request for ip-address
  rip=${rip:+--request $rip}

  # specific options to request
  ropt='-O lease -O domain -O dns -O hostname -O subnet -O router -O serverid -O broadcast'

  # optional request for bootfile 
  rbf=${rbf:+-O $rbf}

  # run-script: /usr/share/udhcpc/default.script
  rs='-s /usr/share/udhcpc/wb.script'

  # The 'wb.script' file handles states and writes to a leases file.
  # options: vb, log_file, leases_file, resolv_conf
  export udhcpc_Settings="vb=$vb log_file=$ifrc_Log"

  # Client normally continues running in background, and upon obtaining a lease.
  # May be signalled or spawned again depending on events/conditions. Flags are: 
  # iface, verbose, request-ip, exit-no-lease/quit-option, exit-release, retry..
  # for retry, send 4-discovers, paused at 2sec, and repeat after 5sec
  # the request-bootfile option is conditional, other options are required
  eval udhcpc -i $dev $vb $rip $nq -R -t 4 -T 2 -A 5 -o $ropt $rbf $rs $nv
  #
  return $?
}

run_dhclient()
{
  # WARNING:
  # some issues not fully vetted...
  # there are many filed bugs and this app contains dead code
  dhclient -d -v $dev \
   -pf /var/log/dhclient.$dev.pid \
    >/var/log/dhclient.$dev.log 2>&1
  #
  return $?
}

run_dhcpcd()
{
  # dhcpcd is not supported
  #
  return 1 #$?
}

run_dhcp3c()
{
  # dhcp3-client is not supported
  #
  return 1 #$?
}

gipa()
{
  ipa=$( ifconfig $dev |sed -n 's/inet\ addr:\([0-9.]*\) .*/IP address: \1/p' )
  if [ -n "$ipa" ]
  then
    echo "okay, got lease for $dev: $ipa" >>$ifrc_Log 
    return 0
  fi
  return 1
}

#
#
#

if [ -n "$pre_cfg_do" ]
then
  msg "   pre_cfg_do"
  ( eval $pre_cfg_do )&
          pre_cfg_do=
fi
#
# The interface exists and is ready to be configured.
# And so the specified method and optional parameters will now be applied.
#
case ${IFRC_METHOD%% *} in
  
  loopback) ## method
    ifrc_validate_loopback_method_params
    show_filtered_method_params $vm
    # use default ip if none specified
    [ -z "$ip" ] && ip=127.0.0.1
    msg "configuring localhost address $ip"
    ifconfig $dev $ip
    # probably don't need anything beyond this
    ;;

  manual) ## method ...no params
    # do nothing, configuration is to be handled manually
    ;;
    
  static) ## method + optional params
    ifrc_validate_static_method_params
    show_filtered_method_params $vm
    # configure interface <ip [+nm]>
    if [ -z "$ip" ]
    then
      msg "configuration in-complete, need at lease the ip"
      show_filtered_method_params $vm
    else
      if [ -z "$nm" ]
      then
        ifconfig $dev $ip
      else
        ifconfig $dev $ip netmask $nm
      fi
    fi
    #
    # add to the routing table
    if [ -n "$gw" ]
    then
      msg route add default gw $gw $dev
      route add default gw $gw $dev
    fi
    #
    # add nameservers
    if [ -n "$ns" ]
    then
      echo "# statically assigned via ifrc" >/etc/resolv.conf
      for x in $ns
      do
        echo "nameserver ${x##=*}" >>/etc/resolv.conf
      done
      echo >>/etc/resolv.conf
    fi
    ;;

  dhcp) ## method + optional params
    ifrc_validate_dhcp_method_params
    show_filtered_method_params $vm

    check_link

    ## allow using a fixed-port-speed-duplex, intended only for wired ports
    if ! grep -q $dev /proc/net/wireless && [ -n "$mii" ]
    then
      [ -n "$fpsd" ] \
      && $mii -F $fpsd $dev 2>&1 |grep "[vb]a[ls][ue]" 
    fi

    ## spawn a dhcp client
    # need sub-method for allowing way to select the favored client
    # may want to implement a governor to limit futile requests
    # busybox-udhcpc is the most efficient and well maintained
  # ( run_dhcp3c )&
  # ( run_dhcpcd )&  
  # ( run_dhclient )&
    ( run_udhcpc )&
    [ $? ] || msg "  ...the dhcp client failed"
    usleep 666666
    echo -en \\\r 
    if [ -n "$to" ]
    then
      # wait for ip-address and exit non-zero if timeout...  
      # there will not be any automatic restart nor netlink event
      msg3 "using timeout of $to seconds"
      while [ $to -gt 0 ]
      do
        [ "${vm:0:1}" == "." ] && echo -en .
        sleep 1
        let to-=1
        gipa && { to=; break; }
      done
      [ "${vm:0:1}" == "." ] && echo
      if [ -n "$to" ]
      then
        signal_dhcp_client TERM
        msg "  ...no dhcp offer, timeout (error)"
        exit 1;
      fi
    fi
   
    ## restart auto-negotiation after using fixed speed
    # developmental...
    #[ -n "$fpsd" ] && [ -n "$mii" ] && $mii -r $dev >/dev/null
    # well... restoring this has another side-effect...
    # disabled for now, so the fpsd will remain in-effect, if used
    ;;
  
  *)
    msg "unhandled, configuration method: ${IFRC_METHOD} (error)"
    exit 1
    ;;
esac
#
# Only can get to this point if we successfully (re-)up'd the interface,
# and it should now be packet-ready.
# If using dhcp, then must employ a timeout, to be certain.
#
if [ -n "$post_cfg_do" ]
then
  msg "   post_cfg_do"
  ( eval $post_cfg_do )&
          post_cfg_do=
fi
exit 0 
