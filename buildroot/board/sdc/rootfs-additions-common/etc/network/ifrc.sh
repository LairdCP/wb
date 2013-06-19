#!/usr/bin/env ash
# /etc/network/ifrc.sh - interface_run_config
# A run-config/wrapper script to operate on kernel-resident network interfaces.
# Provides auto-reconfiguration via netlink support.
# ksjonh_20120520
#
usage() {
  rv=0
  [ "${1:0:5}" == "error" ] \
  && { echo -e "${2:+  $2\n}${3:+\nUsage:\n# $3\n}#"; rv=1; pause 3; }
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

msg() {
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
ifrc_Version=20130619
ifrc_Disable=/etc/default/ifrc.disable
ifrc_Script=/etc/network/ifrc.sh
ifrc_Time= #$( date +%s.%N )
ifrc_Log=/var/log/ifrc
ifrc_Cmd="$0 $@"
ifrc_Via=
ifrc_Pid=$$

# ensure ifrc exists as a system executable
ifrc=/sbin/ifrc
[ -x "$ifrc" ] || ln -sf $ifrc_Script $ifrc

# check init-script exists
nis=/etc/init.d/S??network*
[ -x $nis ] || msg "warning: network init-script ($nis) not found!"

# /e/n/i should exist...
eni=/etc/network/interfaces
[ -f $eni ] || touch $eni

# check mii (optional)
mii=/usr/sbin/mii-diag
if [ ! -x "$mii" ]
then
  mii=
else
  # this package is used to optionally set a fixed port speed during dhcp
  mii_speed="portspeed=10baseT...   - use fixed port speed during dhcp trial"
fi

parse_flag() {
  case $1 in
    \?|-h|--help|--usage) ## show usage
      usage
      ;;
    --|--version) ## just report version
      msg ${ifrc_Script##*/} $ifrc_Version
      exit 0
      ;;
    -r) ## remove all related ifrc log files on startup
      for f in /var/log/ifrc*; do rm -f $f && msg ${f##*/} log removed; done
      let $#-1 && return 1 || exit 0
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
      msg \ \ ...ignoring: $1
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

pause() { 
  # n[.nnn] sec
  # zero value means indefinite
  read -rst${1:-1} <>/dev/zero 2>/dev/null
  if test $? -eq 2 
  then
    s="${1/.*}"
    us="000000"
    [ -z "${1/*.*}" ] && us="${1/*.}$us"
    usleep $s${us:0:6}
  fi
  return 0
}

gipa() {
# ip addr show $1 2>/dev/null \
  ifconfig $1 2>/dev/null \
    |sed -n '/inet/s/.*[: ]\([0-9.]*[0-9]\)[\/ 0-9]*[Bb].*/\1/p' |grep .
}

sleuth_wl() {
  # try to find kernel-resident (wireless) interface: wl
  # in this case, it is not certain what the name is ahead of time
  for x in /sys/class/net/*/wireless
  do
    x=${x##*/sys/class/net/}; x=${x%%/*}; [ "$x" != \* ] && { echo $x; break; }
  done
}

show_interface_config_and_status() {
  ida=$( ifconfig -a |sed -n '/./{H;$!d;};x;/\ UP/!p' \
                     |sed -n 's/\(^[a-z][a-z0-9]*\).*/\1 /p' \
                     |tr -d '\n' )

  [ -z "$dev" -a -n "$ida" ] \
  && echo "       Available, but not configured: $ida"
  echo
  ifconfig |sed -n "/packe/d;/queue/d;/nterr/d;/cope/d;/${dev:-.}/,/^$/p;" \
           |sed 's/^\(.......\)\ *\([^ ].*[^ ]\)\ */\1\2/g; s/0-0/0:0/g' \
           |sed 's/^$/       /; $d' |grep ....... || return 1

  test -z "$dev" && dev=$( sleuth_wl )
  #
  # include association info for wireless dev
  if [ -n "$dev" ] \
  && [ -d /sys/class/net/$dev/wireless ]
  then
    echo -e "\nWiFi:"
    #iwconfig 2>/dev/null
    iw dev $dev link 2>/dev/null \
      |sed 's/^Connec/Associa/;s/t connec.*/t associated (on '$dev')/' \
      |sed '/[RT]X:/d;/^$/,$d;s/^\t/              /'
    #
    # too slow
    #sdc_cli profile list |sed -n 's/\(.*\) ACTIVE/WiFi profile: \1/p'
  fi
  return 0
}

ifrc_stop_netlink_daemon() {
  prg="ifplug[d]"
  # find all ifplug* instances for this interface  
  for pid in \
  $( ps |sed -n "/${dev}/s/^[ ]*\([0-9]*\).*[\/ ]\(${prg}\)[ -].*/\1_\2 /p" )
  do
    kill ${pid%%_*} \
    && msg1 @. "`printf \"% 7d %s <-sigterm\" ${pid%%_*} ${pid##*_}`"
  done
}

signal_dhcp_client() {
  case $1 in
    USR1) action=sigusr1; signal=-10;;
    TERM) action=sigterm; signal=-15;;
    CONT) action=sigcont; signal=-18;;
    ZERO) action=sigzero; signal=-00;;
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
      msg1 @. "`printf \"% 7d %s <-${action}\" ${pid%%_*} ${pid##*_}`"
      let rv=0
    else
      let rv=1
    fi
  done

  # interrupt link-beat check, while in-progress
  rm /tmp/ifrc.$dev.lbto 2>/dev/null && pause 0.2
  return $rv
}

make_dhcp_renew_request() {
  for x in 1 2 3 4 5
  do
    msg1 \\\trenew_req: $x
    { read -r txp_a </sys/class/net/$dev/statistics/tx_packets; } 2>/dev/null
    signal_dhcp_client USR1 && pause 1 || break
    let txp_b=$txp_a
    { read -r txp_a </sys/class/net/$dev/statistics/tx_packets; } 2>/dev/null
    msg2 \\\ttx_packets: $txp_a-$txp_b
    let $txp_a-$txp_b && return 0
  done
  msg1 \\\tfailed...
  return 1
}

store_ap_info() {
  ap=$( iw dev $dev link \
      |sed -n 's/.* \(..:..:..:..:..:..\) .*/\1/p;s/.*SSID: \(.*\)/\1/p' \
      |tr '\n' ' ' )

  [ -n "$ap" ] \
  && sed "1s/^.*/\tap: ${ap}/" -i /var/log/ifrc.$dev
}

# 
# the 1st arg should be an interface dev name
# however, some actionable exceptions can be handled before qualifing iface dev
case $1 in

  stop|start|restart) ## call network-init-script w/action-&-args, no return
    [ -n "${vm:0:1}" ] && set -x
    exec $nis "" $1 $2
    ;;
  
  show|"") ## iface missing, and no other action, so show any/all
    echo "Configuration for all interfaces" \
         "                          (try -h to see usage)"
    if show_interface_config_and_status 
    then
      echo
      /etc/network/bridge.sh 2>/dev/null
      route -ne
      echo -e "\nDNS:\r\t/etc/resolv.conf"
      sed '$G' /etc/resolv.conf 2>/dev/null
    fi
    if [ -n "${vm:0:1}" ]
    then
      echo Processes:
      ps -o pid,args \
      |grep -E 'dhc[pl]|ifplug[d]|wi[rf][ei]|sup[p]|ne[t]|br[i]' || echo \ \ ...
    fi
    exit 0
    ;;

  help) ## view the readme file
    less -Em~ /etc/network/networking.README
    # NOTE - the EOF detect/quit is not working in bb_1.19.3 - bb_1.21.0
    exit 0
    ;;

  eni) ## edit the /e/n/i file
    cp -f $eni /tmp/ifrc.${eni##*/}~
    if /bin/vi /tmp/ifrc.${eni##*/}~ -c /^iface\ $2 \
    && ! cmp -s /tmp/ifrc.${eni##*/}~ $eni
    then
      let $( ls -s /tmp/ifrc.${eni##*/}~ |sed 's/\ *\([0-9]\+\).*/\1/' )+0 \
      && mv -f /tmp/ifrc.${eni##*/}~ $eni \
      || echo "unable to copy edited $eni into place"
    fi
    exit 0
    ;;  

  noauto|auto|flags|status|down|dn|up) ## require iface
    usage error: "...must specify an interface" "ifrc <iface> $1" 
    ;;

  [a-z][a-z]*) ## accept an <iface> dev name starting with two letters
    dev=$1 && shift
    ;;

  *) usage error: "...invalid interface name";;
esac

#
# Generally, operations are on a specific interface.
# It is possible that the $dev may initially be unknown.
# So, for /e/n/i file lookups, we assume the use of $devalias.
#
if [ ! -f $eni ]
then
  # Without having the /e/n/i file, then given interface and settings must be
  # explicitly provided.  Although, method 'dhcp' will be ultimately assumed.
  #
  # Handle some dev name exceptions here first.
  [ "$dev" == "wl" ] && devalias=$( sleuth_wl )
  #
elif [ -n "$dev" ]
then
  # See if this is an aliased interface to act on...
  # Otherwise (assume) treat the interface as an alias by the same name.
  # when given dev is the alias for an interface name, determine actual name
  # when given dev is the actual interface name of an alias, use as an alias
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
  test -n "$devalias" || exit 1
  ## devalias now is set, and used to further process settings from /e/n/i
  #
  # check for ifrc-flags if none specified on cli - cummulative
  test -z "$ifrc_Settings" \
  && flags=$( sed -n "/^iface $devalias/,/^$/\
                      s/^[ \t]\+[^#]ifrc-flags \(.*\)/\1/p" $eni 2>/dev/null )
  #
  [ -n "$flags" ] \
  && msg3 "applying ifrc-flags via /e/n/i: $flags"
  for af in $flags; do parse_flag $af; done

  # check for ifrc-pre/post-d/cfg-do scripts
  if [ -z "$ifnl_s" ] \
  && [ -z "$IFRC_SCRIPT" -a -n "$devalias" ]
  then
   msg3 "parsing /e/n/i for pre/post commands, intended for $dev..."
   IFRC_SCRIPT=$( sed -n "/^iface $devalias/,/^$/\
       s/^[ \t][ ]*\([^#]p[or][se][t]*\)-\([d]*cfg\)-do \(.*\)/\1_\2_do='\3'/p"\
     $eni 2>/dev/null )
    #
    msg3 $IFRC_SCRIPT
    eval $IFRC_SCRIPT
  fi
fi
test -n "$dev" || exit 1

# set logfile name and limit the file size to just 100-blocks
if [ "$ifrc_Log" != "/dev/null" ]
then
  ifrc_Log=${dev:+$ifrc_Log.$dev}
  let sz=$( ls -s $ifrc_Log 2>/dev/null |sed 's/\ *\([0-9]\+\).*/\1/' )+0
  test $sz -le 100 || ifrc_Log=/dev/null
fi

# begin a new log entry for the operations that follow 
echo -e "\n`date +'%b %e %H:%M:%S'` __${ifrc_Cmd}  $ifrc_Via" >>$ifrc_Log
msg3 "` env |sed -n 's/^IF[A-Z]*_.*/  &/p' |sort`"

# external globals - carried per instance and can be used by *-do scripts too 
export IFRC_STATUS="${ifnl_s:-  ->  }"
export IFRC_DEVICE=$dev
export IFRC_ACTION
export IFRC_METHOD
export IFRC_SCRIPT

# determine action to apply - assume 'show'
[ -n "$1" ] && { IFRC_ACTION=$1; shift; } || IFRC_ACTION=show

# determine method to apply
if [ "$IFRC_ACTION" == "up" ]
then
  ## assume method [and params] if not specified via cli or eni
  if [ -z "$IFRC_METHOD" ]
  then
    if [ -n "$1" ]
    then
      methvia="(set via cli)"
      IFRC_METHOD="$@"
    elif [ -f $eni ]
    then
      methvia="(via /e/n/i)"
      IFRC_METHOD=$( sed -n "s/^iface $devalias inet \([a-z]*\)/\1/p" $eni )
      mp=$( sed -n "/^iface $devalias inet $IFRC_METHOD/,/^$/s/^[ \t][ ]*\([^#][a-z]*\)[ ]\(.*\)/\1=\2/p" $eni )
      IFRC_METHOD=$IFRC_METHOD\ $mp
    fi
    if [ -z "$IFRC_METHOD" ]
    then
      methvia="(assummed)"
      IFRC_METHOD="dhcp"
    fi
  fi  
fi  

# determine netlink event rule to apply
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
      pause 2
      if [ ! -f /sys/class/net/$dev/carrier ]
      then
        msg1 $dev is gone, so allowing deconfiguration
        IFRC_ACTION=dn
      else
        msg1 ignoring dn event for dhcp method - iface is back
        IFRC_ACTION=xxx
      fi
    else
      if [ "${IFRC_METHOD%% *}" == "dhcp" ]
      then
        # retain-inactive-ipaddr is for loss of link behavior when..;
        # no, then flush and attempt renew/request later
        # yes, then keep everything as is, even though invalid
        # auto, then flush and restore before renew/request
        if [ "${RETAIN_INACTIVE_IPADDR:-no}" != "yes" ]
        then
          msg1 deconfigure iface for dhcp method - still active
          #( interface=$dev /etc/dhcp/udhcpc.script deconfig )
          
          ifconfig $dev 0.0.0.0 2>/dev/null
        fi
        IFRC_ACTION=xxx
      fi
    fi
  fi
  
  ## event rules for '->up'
  if [ "${IFRC_STATUS##*->}" == "up" ]
  then
    if [ "${IFRC_METHOD%% *}" == "dhcp" ]
    then
      # check if dhcp client is running
     #signal_dhcp_client CONT && IFRC_ACTION=...
      signal_dhcp_client ZERO && IFRC_ACTION=...
      store_ap_info      
    fi
  fi

  ##
  ## additional rules can handle other condition/states here...
  ##
fi


msg @. ifrc_s/d/a/m/s: "$IFRC_STATUS" $IFRC_DEVICE ${IFRC_ACTION:-.} m:${IFRC_METHOD%% *} s:$IFRC_SCRIPT

#
# Do not really 'down' or 'up' an interface here with: 'ifconfig <dev> down/up'
# We leave that to the driver init-scripts instead, so they handle stop/start.
# This script uses down/up with respect to interface (de)configuration only!!
#
case $IFRC_ACTION in
  status) ## check if iface is configured and show its ip-address
    ## confirm configured <iface>: [ip-address]:0/1
    ip=$( gipa $dev )
    test -n "$ip" && { msg $ip; exit 0; } || exit 1
    ;;

  show) ## show info/status for an iface
    test -f /sys/class/net/$dev/uevent \
    || { echo \ \ ...not available, not a kernel-resident interface; exit 1; }
    
    # summarize the status of this interface
    { read -r ccl </sys/class/net/$dev/carrier; } 2>/dev/null
    [ "$ccl" != "1" ] && ccl="no carrier/cable/link" || ccl="linked"

    iw dev $dev link |grep -q Connected \
    && ccl="$ccl, associated"
    
    ps |grep -q "ifplug[d].*${dev}" && ccl="managed, $ccl" 
    ifconfig $dev |grep -q UP && ccl="$ccl, up" || ccl="$ccl, dn"

    echo -e "Configuration for interface: $devalias $ifacemsg ...$ccl"
    if grep -qs Generic /sys/class/net/$dev/*/uevent
    then
      echo Warning: using 'Generic PHY' driver
      [ -n "$mii" ] && $mii $dev |sed -n '/You/,$d;/media type/,$p'
    fi
    show_interface_config_and_status
    #netstat -nre |grep -E "Kernel|Destina|$dev"
    #route -ne |grep -E "Kernel|Destina|$dev"
    if [ "$dev" == "lo" ]
    then
      echo -e "\nRouting: (local)"
      ip route show table local dev $dev |sed 's/local/    local/'
    else
      echo -e "\nRouting: "
      ip route show dev $dev
      # get arp-table entries count, then display entries
      let `arp -ani $dev |sed '/No match/d; $=; d'`+0 && x=cached || x=empty
      echo -e "\nARP:\r\t($x)" && arp -ani $dev |sed '/No match/d;/^$/d'
    fi
    [ -n "${vm:0:1}" ] \
    && echo -e "\nProcesses:\n`ps -o pid,args |grep "$dev[ ]" || echo \ \ ...`"
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
    [ -n "${vm:0:1}" ] && echo "/e/n/i: `grep "auto $devalias" $eni`"
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
    [ -n "${vm:0:1}" ] && echo "/e/n/i: `grep "auto $devalias" $eni`"
    exit 0
    ;;

  stop|start|restart) ## act on init/driver, does not return
    [ -n "${vm:0:1}" ] && set -x
    exec $nis $devalias $IFRC_ACTION
    ;;

  dn|down) ## assume down action ->deconfigure
    ##
    if [ -n "$pre_dcfg_do" ]
    then
      msg "   pre_dcfg_do $pre_dcfg_do"
      ( eval $pre_dcfg_do |tee -a $ifrc_Log )&
              pre_dcfg_do=
    fi
    rm -fv /var/log/ifrc.$dev.lock
    msg1 "deconfiguring $dev"
    #
    # terminate any other netlink/dhcp_client daemons and de-configure
    ifrc_stop_netlink_daemon 
    signal_dhcp_client TERM
    #
    # de-configure (flush) only on an 'up' interface
    { read -r operstate </sys/class/net/$dev/operstate; } 2>/dev/null
    [ "$operstate" == "up" ] \
    && { ifconfig $dev 0.0.0.0 2>/dev/null; pause 0.333; }
    ##
    if [ -n "$post_dcfg_do" ]
    then
      msg "   post_dcfg_do $post_dcfg_do"
      ( eval $post_dcfg_do |tee -a $ifrc_Log )&
              post_dcfg_do=
    fi
    exit 0
    ;;

  up) ## assume up action ->reconfigure . . .
    if [ ! -f /sys/class/net/$dev/uevent ]
    then
      if [ ! -f /var/log/ifrc.$dev.lock ]
      then
        touch /var/log/ifrc.$dev.lock
        IFRC_METHOD=
        IFRC_SCRIPT=
        msg "interface is not kernel-resident, trying to start ..."
        msg1 "$nis $devalias start $IFRC_METHOD"
        exec $nis $devalias start $IFRC_METHOD
      else
        msg "interface is not kernel-resident, try:  ifrc $dev start"
        exit 1
      fi
    fi
    rm -fv /var/log/ifrc.$dev.lock
    
    if [ "$dev" != "lo" ] \
    && [ "$devalias" != "wl" ] \
    && [ ! -d /sys/class/net/$dev/wireless ]
    then
      # ethernet wired phy-hw is external; so try to determine if really there
      # the generic phy driver is present when phy-hw is otherwise unsupported
      if grep -s Generic /sys/class/net/$dev/*/uevent >/dev/stderr
      then
        msg "warning: unknown '$dev' iface-phy-hw ...using generic phy driver"
        [ -z "$mii" ] && exit 1 || $mii $dev |grep -B12 fault && exit 2
      fi
    fi
    [ "${IFRC_STATUS%%->*}" == "up" ] && re=re- || re=
    msg1 "${re}configuring $dev using ${IFRC_METHOD%% *} method $methvia"
    #
    # terminate any other netlink/dhcp_client daemons and de-configure
    [ -z "$ifnl_s" ] && ifrc_stop_netlink_daemon 

    # this is a new method/request
    signal_dhcp_client TERM

    ifconfig $dev 0.0.0.0 2>/dev/null \
    || msg "  ...deconfig for up_action resulting in error, ignored"
    ## this de-configure (flush) will also re-'up' the interface...
    ## additional wait time may be required to be ready again
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
        msg @. \ \ ...exec ifrc $fls $dev up $IFRC_METHOD
        rm -f /var/log/ifrc.$dev.lock
        eval exec ifrc $fls $dev up $IFRC_METHOD
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
    usage error: "...invalid action specified"
    ;;
esac

#
# The rest of this script handles the configuration of an interface.
# And is run when called again manually, or via the netlink daemon.
#
# Firstly, ensure that the netlink daemon is active for <interface>.
# Exceptions:
[ "${IFRC_METHOD%% *}" == "manual" ] && ifnl_disable=.
[ "$dev" == "lo" ] && ifnl_disable=.

if [ -n "$ifnl_disable" ]
then
  ifrc_stop_netlink_daemon
else
  if ! { ps |grep -q "ifplug[d].*${dev}" && msg "  ...nl-daemon is running"; }
  then
    [ -n "${vm:0:1}" ] && nsl= || nsl=-s
    #
    # dameon will terminate on error, or if run-script exits w/non-zero status
    ifplugd -i$dev -M $nsl -q -p -a -f -u1 -d0 -I -r$0
    #pause 0.333
  fi
fi

#
# NOTE:
# The script will exit with a zero value even if configuration is deferred.
# This is considered a valid state, and upon a netlink event, configuration
# is automatically re-attempted via the netlink daemon, such as:
# 1. wifi is not associated yet (handled by supplicant)
# 2. cable/link not present yet
#
# The script will exit with a non-zero value whenever a permanent condition
# prevents configuration of the interface, such as:
# 1. invalid method specified
# 2. no hw-phy detectable
# 3. timeout was used
# 4. other errors
#
# It is unwise to wait on ifrc, as called, for a configuration to complete.
# Instead, check configuration with:
#
# ...a simple timed-loop test for "inet addr":
# $( if ifconfig <iface> 2>/dev/null |grep -q 'inet addr'; then true; fi )
#
# ...or use ifrc to check status:
# $( if ifrc <iface> status; then true; fi )
# 

show_filtered_method_params() {
  #if [ "${vm:0:2}" == ".." ]
  if [ -n "$vm" ] 
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

ifrc_validate_loopback_method_params() {
  IFS=$'\n'
  for x in ${IFRC_METHOD/loopback /}
  do IFS=' '
    echo $x |grep -q "[ia][a-z]*=[0-9].*" \
    || { msg2 "ignoring invalid extra parameter: $x"; continue; }
    case $x in
      ip=*|address=*)
        ip=${x##*=}
        ;;
      *)
        msg2 "ignoring extra parameter: $x"
    esac
  done; IFS=' '
  show_filtered_method_params
}

ifrc_validate_static_method_params() {
  IFS=$'\n'
  for x in ${IFRC_METHOD/static /}
  do IFS=' '
    echo $x |grep -q "[aingb][a-z]*=[0-9]*.[0-9]*.[0-9]*.[0-9]*[/0-9]*" \
    || { msg2 "ignoring invalid extra parameter: $x"; continue; }
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
        msg2 "ignoring extra parameter: [$x]"
    esac
  done; IFS=' '
  show_filtered_method_params
}

ifrc_validate_dhcp_method_params() {
  IFS=$'\n'
  for x in ${IFRC_METHOD/dhcp /}
  do IFS=' '
    echo $x |grep -q "[iatpfc][a-z]*=[0-9].*" \
    || { msg2 "ignoring invalid extra parameter: $x"; continue; }
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
#      client=*) ## specify a preferred client
#        client=${##*=}
#        ;;
      *)
        msg2 "ignoring extra parameter: $x"
    esac
  done; IFS=' '
  ipa=
  show_filtered_method_params
}

check_link() {
  # check if associated when using wireless
  if [ -d /sys/class/net/$dev/wireless ]
  then
    grep -q 1 /sys/class/net/${dev}/carrier \
    && grep -qs up /sys/class/net/${dev}/operstate \
    || { msg "  ...not associated, deferring"; exit 0; }
  fi
  store_ap_info

  # need a link beat in order for dhcp to work
  # so try waiting up to 30s, and then double check
  touch /tmp/ifrc.$dev.lbto
  let lbto=30000
  let n=0
  while [ $n -lt $lbto -a -f /tmp/ifrc.$dev.lbto ]
  do
    grep -q 1 /sys/class/net/${dev}/carrier && break
    let n+=200 && pause 0.2
  done
  rm -f /tmp/ifrc.$dev.lbto

  grep -q 1 /sys/class/net/${dev}/carrier \
  || { msg "  ...no carrier/cable/link, deferring"; exit 0; }

  [ $n -gt 0 ] && msg "  waited ${n}ms on ${dev}/carrier"
}

run_udhcpc() {
  # BusyBox v1.19.3 multi-call binary.
  source /etc/dhcp/udhcpc.conf 2>/dev/null
  
  # set no-verbose or verbose mode level
  [ -z "$vm" ] && nv='|grep -E "obtained|udhcpc"'
  [ "${vm:2:1}" == "." ] && vb='-v' 
  [ "${vm:1:1}" == "." ] && q=

  # optional exit-no-lease and quit
  nq=

  # request ip-address (given via cmdline)
  rip=${rip:+--request $rip}

  # specific options to request in lieu of defaults
  for t in ${OPT_REQ}; do ropt=$ropt\ -O$t; done
  ropt=${ropt:+-o $ropt}

  # vendor-class-id support (as last line of file or a string)
  vci=$( sed '$!d;s/.*=["]\(.*\)["]/\1/' ${OPT_VCI:-/} 2>/dev/null \
      || echo "$OPT_VCI" )
  vci=${vci:+--vendorclass $vci}
  ropt=${ropt}${vci:+ -O43}

  # specific opt:val pairs to send - must be hex
  for t in ${OPT_SND}; do xopt=$xopt\ -x$t; done
  
  # request bootfile (via flag-file)
  rbf=${rbf:+-O$rbf}

  # run-script: /usr/share/udhcpc/default.script
  rs='-s/etc/dhcp/udhcpc.script'

  # The run-script handles client states and writes to a leases file.
  # options: vb, log_file, leases_file, resolv_conf
  export udhcpc_Settings="vb=$vb log_file=$ifrc_Log"

  # Client normally continues running in background, and upon obtaining a lease.
  # May be signalled or spawned again depending on events/conditions. Flags are: 
  # iface, verbose, request-ip, exit-no-lease/quit-option, exit-release, retry..
  # For retry, send 4-discovers, paused at 2sec, and repeat after 5sec.
  eval udhcpc -i$dev $vb $rip $nq -R -t4 -T2 -A5 $ropt $vci $xopt $rbf $rs $nv
  #
  #return $?
}

run_dhclient() {
  # Internet Systems Consortium DHCP Client 4.1-ESV-R4
  # Usage: dhclient [-4|-6] [-SNTP1dvrx] [-nw] [-p <port>]
  #                 [-s server-addr]
  #                 [-cf config-file] [-lf lease-file]
  #                 [-pf pid-file] [--no-pid] [-e VAR=val]
  #                 [-sf script-file] [interface]
  #
  # WARNING:
  # some issues not fully vetted...
  # there are many filed bugs and this app contains dead code

  # -cf /etc/dhcp/dhclient.$dev.conf \
  # -pf /var/log/dhclient.$dev.pid \
  
  dhclient -d -v $dev --no-pid \
   -lf /var/lib/dhcp/dhclient.$dev.leases \
    >/var/log/dhclient.$dev.log 2>&1
  #
  #return $?
}

run_dhcpcd() {
  : dhcpcd is not yet supported
  #
  #return 1 #$?
}

run_dhcp3c() {
  : dhcp3-client is not yet supported
  #
  #return 1 #$?
}

await_timeout_for_dhcp() {
  # wait for ip-address and exit non-zero if timeout...  
  # there will not be any automatic restart nor netlink event
  msg3 "using timeout of $to seconds"
  while [ $to -gt 0 ]
  do
    [ "${vm:0:1}" == "." ] && echo -en .
    pause 1
    let to-=1
    gipa && { to=; break; }
  done
  [ "${vm:0:1}" == "." ] && echo
  if [ -n "$to" ]
  then
    signal_dhcp_client TERM
    msg "  ...no dhcp offer, timeout (error)"
    exit 1
  fi
}


if [ -n "$pre_cfg_do" ]
then
  msg "   pre_cfg_do $pre_cfg_do"
  ( eval $pre_cfg_do |tee -a $ifrc_Log )&
          pre_cfg_do=
fi
#
# The interface exists and is ready to be configured.
# And so the specified method and optional parameters will now be applied.
#
case ${IFRC_METHOD%% *} in
  
  dhcp) ## method + optional params
    [ -n "$rcS_" -a -f /tmp/bootfile_ ] && rbf=bootfile
    ifrc_validate_dhcp_method_params
    check_link
    ## allow using a fixed-port-speed-duplex, intended only for wired ports
    if [ ! -d /sys/class/net/$dev/wireless ] && [ -n "$mii" ]
    then
      [ -n "$fpsd" ] \
      && $mii -F $fpsd $dev 2>&1 |grep "[vb]a[ls][ue]" 
    fi

    ## spawn a dhcp client in the background
    # may want to implement a governor to limit futile requests
    # busybox-udhcpc is the most efficient and well maintained
    case ${client:-udhcpc} in
      dhclient)
        run_dhclient &
        ;;
      udhcpc)
        run_udhcpc &
        ;;
      dhcp3c|dhcpc3-client)
        run_dhcp3c &
        ;;
      dhcpcd)
        run_dhcpcd &
        ;;
      *)
        ;;
    esac
    pause 1
    echo -en \\\r 

    test -n "$to" && await_timeout_for_dhcp 
   
    ## restart auto-negotiation after using fixed speed
    # developmental...
    #[ -n "$fpsd" ] && [ -n "$mii" ] && $mii -r $dev >/dev/null
    # well... restoring this has another side-effect...
    # disabled for now, so the fpsd will remain in-effect, if used
    ;;
  
  static) ## method + optional params
    ifrc_validate_static_method_params
    # configure interface <ip [+nm]>
    if [ -z "$ip" ]
    then
      msg "configuration in-complete, need at lease the ip"
    else
      ifconfig $dev $ip ${nm:+netmask $nm}
    fi
    # add to the routing table
    if [ -n "$gw" ]
    then
      msg route add default gw $gw $dev
      route add default gw $gw $dev
    fi
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

  loopback) ## method + optional params
    ifrc_validate_loopback_method_params
    # use default ip if none specified
    [ -z "$ip" ] && ip=127.0.0.1
    msg "configuring localhost address $ip"
    ifconfig $dev $ip
    # probably don't need anything beyond this
    ;;

  manual) ## method ...no params
    # do nothing, configuration is to be handled manually
    ;;
    
  *) ## error
    msg "unhandled, configuration method: ${IFRC_METHOD%% *} (error)"
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
  msg "   post_cfg_do $post_cfg_do"
  ( eval $post_cfg_do |tee -a $ifrc_Log )&
          post_cfg_do=
fi
exit 0 
