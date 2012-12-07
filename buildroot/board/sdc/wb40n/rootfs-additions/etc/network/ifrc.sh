#!/usr/bin/env ash
# /etc/network/ifrc.sh - interface_run_config
# A run-config/wrapper script to operate on kernel-resident network interfaces.
# Provides auto-reconfiguration via netlink support.
# ksjonh_20120520
#
usage()
{
  [ -n "${1:3}" ] && echo "${@:3}"
  cat <<-	end-of-usage-info-block
	$( ls -l $0 |grep -o $0.* )
	Shows network interface configurations.
	And, configures an interface to use netlink and dhcp/static methods.
	Can work with settings from /etc/network/interfaces or the commandline.
	You can "re" up an interface to change/update the method/ip-address.
	
	  ( Note: ifrc may be disabled with:  /etc/default/ifrc.disable )
	
	Flags:
	  -h   this helpful summary
	  -t   test only, no action
	  -q   be quiet, no stdout
	  -v   be more verbose ...
	  -n   no logging to files
	  -r   remove the log files
	  -x   run w/o netlink daemon
	  -m   monitor nl/ifrc events
  
	Interface:
	  must be kernel-resident of course
	  can be an alias (such as 'wl' for wireless)

	Action:
	  stop|start|restart   - act on phy-init/driver (up/down the hw-phy)
	  auto|noauto   - set or unset auto-starting interface at bootup (via init)
	  status   - check a configured interface and report its ip-address
	  up|dn   - up or down the interface configuration (up/down the iface)
	  show   - specific interface info, or general info (default action)
	  eni   - edit file: /etc/network/interfaces
	  help   - view file: /etc/network/networking.README
	
	Method:
	  dhcp [<param=value> ...]
	     - employ client to new get lease, info stored in leases file
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
	end-of-usage-info-block
  #
  exit ${1:1:1}
}

msg()
{
  # to console if special prefix
  if [ "$1" == "@." ] && shift
  then
    echo -e "$@" >>/dev/console
  else
   # to stdout if not quiet
   [ -z "$q" ] && echo "$@" || :
  fi
  
  # to log, unless -n was used
  echo "${@:$o}" >>$ifrc_Log || :
}

#
# internal globals
eni=/etc/network/interfaces
ifrc_=${0##/*}
ifrc_TimeNow=$( date +%s.%N )
ifrc_Log=/var/log/ifrc
ifrc_Cmd="$0 $@"
ifrc_Wait=
ifrc_Via=
#ifrc_Pid=$$
ifnl_=$IFPLUGD_CURRENT

#
# check supporting package options
mii=/usr/sbin/mii-diag
if [ ! -x "$mii" ]
then
  mii=
else
  # this package is used to optionally set a fixed port speed during dhcp
  mii_speed="portspeed=10baseT...   - use fixed port speed during dhcp trial"
fi
if [ ! -x /sbin/ifrc ]
then
  # ensure availablity as system command
  ln -sf /etc/network/ifrc.sh /sbin/ifrc
fi
[ "$1" == "?" ] && usage ~0.


parse_flags()
{
  case $1 in
    -h) ## show usage
      usage ~0.
      ;;
    -t) ## test mode
      T=echo
      ;;
    -r) ## remove all related ifrc log files on startup
      for f in /var/log/ifrc*; do rm -f $f && echo ${f##*/} log removed; done
      ;;
    -n) ## do not use a log file
      ifrc_Log=/dev/null
      ;;
    -q) ## quiet, no stdout
      q='>/dev/null'
      ;;
    -v) ## add verbosity, multi-level
      echo "setting verbose mode"
      v=$v.
      ;;
    -x) ## do not run netlink daemon
      ifnl_disable=.
      ;;
    -m) ## monitor nl/ifrc events for a specific iface
      m=@.
      ;;
    -*) ## ignore
      echo ignoring $1
      ;;
  esac
}
while [ "${1:0:1}" == "-" ]
do
  parse_flags $1
  shift
done

[ -n "$rcS_" ] && [ -f /tmp/bootfile_ ] && bf='-O bootfile'
[ -n "$rcS_" ] && ifrc_Via=" (...via rcS)"
[ -n "$ifnl_" ] && ifrc_Via=" (...via ifplugd)"
[ -n "$ifrc_Via" ]  && q='>/dev/null'
[ "$v" == "...." ] && set -x

# hum...
if [ -f /etc/default/ifrc.disable ]
then
  msg @. "  /etc/default/ifrc.disable exists"
  exit 0
fi


sleuth_wl()
{
  # try to find kernel-resident (wireless) interface: wl
  # in this case, it is not certain what the name is ahead of time
  for x in /sys/class/net/*/wireless
  do
    x=${x##*/sys/class/net/}; x=${x%%/*}; [ "$x" != \* ] && { echo $x; break; }
  done
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
           |sed '/packe/d; /queue/d; /nterr/d; /cope/d; /etric/d' \
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

show_bridge_mode()
{
  bridge_info()
  {
    [ 3 -eq $# ] \
    && echo -e "Bridge mode interface '$1' active using '$2' and '$3'.\n"
  }
  if ps |grep -q S[0-9][0-9]bridge.*start
  then
    echo -e "Bridge mode setting up...\n"
  else
    bmi=$( brctl show |sed -n '2{p;n;p;}' |grep -o [a-z][a-z][a-z]*[0-9] )
    bridge_info $bmi
  fi
}

#
# usually, the 1st arg is an interface, but handle some actionable exceptions
case $1 in

  stop|start|restart) ## iface missing, call network init w/any/all, no return
    #exec /etc/init.d/S??network* $1 $2 $3
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
    if [ -n "${v:0:1}" ]
    then
      ps -o pid,args |grep -E "dhc[pl]|ifplug[d]|wire[l]ess|sup[p]"
    fi
    exit 0
    ;;

  help) ## view the readme file
    less -Em~ /etc/network/networking.README; exit 0
    # note: EOF detection not working in bb_1.3.19
    ;;

  eni) ## edit the /e/n/i file
    cp -f $eni /tmp/ifrc.${eni##*/}~ 2>/dev/null
    if vi $eni && ! cmp -s /tmp/ifrc.${eni##*/}~ $eni
    then
      mv -f /tmp/ifrc.${eni##*/}~ $eni~ 2>/dev/null \
      && echo "a backup copy was saved as $eni~"
    fi
    rm -f /tmp/ifrc.{eni##*/}~
    exit 0
    ;;  

  flags|noauto|auto|status) ## require iface
    usage ~1. require an iface
    ;;
    
  *) ## edit any pre-existing file in /etc/network/
    if [ -f /etc/network/$1 ]
    then #|| { msg "  ! vi /etc/network/$1"; exit 1; }
      cp -f /etc/network/$1 /tmp/ifrc.${1##*/}~
      if vi /etc/network/$1 && ! cmp -s /tmp/ifrc.${1##*/}~ /etc/network/$1
      then
        mv -f /tmp/ifrc.${1##*/}~ /etc/network/$1~ 2>/dev/null \
        && echo "a backup copy was saved as /etc/network/$1~"
      fi
      rm -f /tmp/ifrc.${1##*/}~
      exit 0
    fi
    ;;
esac

dev=$1 && shift
#
# determine dev name/alias
# For operations herein, we generally act on the $dev.
# It is possible that the $dev may initially be unknown.
# So, for /e/n/i file lookups, we assume the use of $devalias.
if [ ! -f $eni ]
then
  # Without having the /e/n/i file, then given interface and settings must be
  # explicitly provided.  Although, method 'dhcp' will be ultimately assumed.
  #
  # Handle some dev name exceptions here first.
  [ "$dev" == "wl" ] \
  && devalias=$( sleuth_wl )
else
  # See if this is an aliased interface to act on...
  # otherwise we treat the interface (and assume) as an alias by the same name.
  # when given dev is the alias for an interface name, determine actual name
  # when given dev is the actual interface name of an alias, copy as alias
  D='[a-z][a-z][a-z0-9]*'
  #msg "  checking the /e/n/i file to determine if aliased interface"
  devalias=$( sed -n "/$dev/s/^[ \t]*alias \($D\)[ is]* \($D\)/\1 \2/p" $eni )
  #msg "  eni_alias: ${devalias%% *}?${devalias##* }"
  deviface=$( sed -n "/$dev/s/^iface $dev.*/$dev/p" $eni )
  #msg "  eni_iface: $deviface?"
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
      #msg "  ...no alias found, so assumed to be real"
    fi
  else
    # found alias, so try to sort out what is the actual name...
    if [ "${devalias%% *}" != "$dev" ]
    then
      ifacemsg="(alias)"
      dev=${devalias##* }
      devalias=${devalias%% *}
      #msg "  ...\"${devalias}\" is the alias for \"${dev}\""
    elif [ "${devalias##* }" != "$dev" ]
    then
      ifacemsg="(alias)"
      dev=${devalias##* }
      devalias=${devalias%% *}
      #msg "  ...assumming \"${dev}\" as \"${devalias}\""
    else
      devalias=$dev
      #msg "  ...can't determine, so assuming $dev"
    fi
  fi
  ##
  # check for ifrc-options
  IFRC_flags=$( sed -n "/^iface $devalias/,/^$/\
   s/^[ \t]\+[^#]ifrc-flags \(.*\)/\1/p" $eni 2>/dev/null )

  [ -n "$IFRC_flags" ] && msg "applying ifrc-flags via /e/n/i: $IFRC_flags"
  for af in $IFRC_flags; do parse_flags $af; done
fi

#
# Extended operations, intended for a specific interface, follow.
# Begin a new log entry and do action . . . 
#
[ -n "$dev" ] && [ "$ifrc_Log" != "/dev/null" ] && ifrc_Log=$ifrc_Log.$dev

echo -e "\n\t`date`\r  ${dev}\n      __${ifrc_Cmd}  $ifrc_Via" >>$ifrc_Log

[ -n "$m" ] && msg $m ifrc:

[ -n "$v" ] && env |grep "^IF[A-Z]*_.*" |sort >>$ifrc_Log

if [ -z "$IFRC_SCRIPT" -a -n "$devalias" ]
then
  #msg "parsing /e/n/i for pre/post commands, intended for $dev..."
  IFRC_SCRIPT=$( sed -n "/^iface $devalias/,/^$/\
   s/^[ \t][ ]*\([^#]p[or][se][t]*\)-\([d]*cfg\)-do \(.*\)/\1_\2_do='\3'/p"\
    $eni 2>/dev/null )
  #
  eval $IFRC_SCRIPT
fi

[ -n "$IFRC_NOTIFY" ] && m=$IFRC_NOTIFY

[ -n "$m" ] && \
msg $m IFRC_s/d/a/m: $IFRC_STATUS $IFRC_DEVICE $IFRC_ACTION $IFRC_METHOD

# external globals - these can be used by *-cfg-do scripts
export IFRC_STATUS="${IFPLUGD_PREVIOUS/down/dn}->${IFPLUGD_CURRENT/down/dn}"
export IFRC_DEVICE=$dev
export IFRC_ACTION
export IFRC_METHOD
export IFRC_METHOD_PARAMS
export IFRC_SCRIPT
export IFRC_NOTIFY=$m

#
# consume remaining args when running via nl daemon
while [ -n "$ifnl_" -a -n "$1" ]; do shift; done

#
# determine action to apply, or assume to just show interface info
if [ -z "$1" ]
then
  ## no action arg passed in...
  if [ -n "$ifnl_" ]
  then 
    # override action and method settings, if via ifplugd
    if [ "$IFPLUGD_PREVIOUS" == "up" ]
    then
      msg "overriding action with 'up'"
      IFRC_ACTION=up
      # method and params already set
    fi
    # can handle other states here...
  else
    # assume 'show' if action undetermined
    IFRC_ACTION=show
  fi
else
  ## an action arg and maybe params, passed in...
  IFRC_ACTION=$1 && shift
  if [ -n "$1" ]
  then
    methvia="(set via cli)"
    IFRC_METHOD=$1 && shift
    IFRC_METHOD_PARAMS="$@"
  fi
fi

#
# determine method to apply for "up" action
if [ "$IFRC_ACTION" == "up" ]
then
  ## determine method and params if not specified
  if [ -z "$IFRC_METHOD" ]
  then
    #msg "determining method for... $devalias"
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

#
#
#

ifrc_stop_netlink_daemon()
{
  prg="ifplug[d]"
  # find all ifplug* instances for this interface, avoid self-termination  
  [ -z "$ifnl_" ] && for pid in \
  $( ps |sed -n "/${dev}/s/^[ ]*\([0-9]*\).*[\/ ]\(${prg}\)[ -].*/\1_\2 /p" )
  do
    kill ${pid%%_*} \
    && [ -n "$v" ] && msg `printf "% 5d %s stopped\n" ${pid%%_*} ${pid##*_}`
  done
}

ifrc_stop_dhcp_client()
{
  prg="[u]*dhc[lp][ic][dent3]*"
  # find all possible clients:  udhcpc, dhclient, dhcpcd, dhcp3-client
  for pid in \
  $( ps |sed -n "/${dev}/s/^[ ]*\([0-9]*\).*[\/ ]\(${prg}\)[ -].*/\1_\2 /p" )
  do
    kill ${pid%%_*} \
    && [ -n "$v" ] && msg `printf "% 5d %s stopped\n" ${pid%%_*} ${pid##*_}`
  done
  # interrupt any link-beat checking
  rm -f /tmp/ifrc.$dev.lbto 
  usleep 199999
}

#
#
#

[ -n "$m" ] && \
msg $m IFRC_s/d/a/m: $IFRC_STATUS $IFRC_DEVICE $IFRC_ACTION $IFRC_METHOD
#
# the main action
case $IFRC_ACTION in
  ##
  ## do not really up/down an interface here with "ifconfig $dev up/down"
  ## we leave that to the init/driver scripts instead, so they handle start/stop
  ## this script uses up/down with respect to interface configuration only
  ##
  up) ## assume up action ->reconfigure . . .
    if [ "$dev" != "lo" ] \
    && [ "$devalias" != "wl" ] \
    && ! grep -q $dev /proc/net/wireless 2>/dev/null
    then
      [ -n "$v" ] && msg "checking wired phy-hw"
      # detection of wired conflicts w/others
      # the interface should be identified... (probably floating hw otherwise)
      if [ ! -f /sys/class/net/$dev/uevent ] \
      || grep -q Generic /sys/class/net/$dev/*/uevent 2>/dev/null
      then
        msg "  ...interface-phy-hw '$dev' is not available"
        exit 1;
      fi
    fi
    if [ ! -f /sys/class/net/$dev/uevent ]
    then
      msg "interface is not available, try:  ifrc $dev start"
      exit 1;
      # although in some cases this works and is helpful
      # is also proves to be problematic for unhandled wireless issues
      #msg "interface is not available, trying to start it using manual method"
      #exec /etc/init.d/S??network* $devalias start manual
    fi
    #[ "$IFPLUGD_CURRENT" == "up" ] && re=re- || re=
    [ "${IFRC_STATUS##*->}" == "up" ] && re=re- || re=
    msg $m "${re}configuring $dev using $IFRC_METHOD method $methvia"
    #
    # terminate any other netlink/dhcp_client daemons and de-configure
    ifrc_stop_netlink_daemon 
    ifrc_stop_dhcp_client 
    ifconfig $dev 0.0.0.0 2>/dev/null \
    || msg "  ...deconfig for up_action resulting in error, ignored"
    ## this de-configure will also re-"up" the interface...
    ## additional wait time may be required to be ready again
    ## operations continue below
    ;;

  dn|down) ## assume down action ->deconfigure
    if [ -n "$pre_dcfg_do" ]
    then
      msg "   pre_dcfg_do"
      ( eval $pre_dcfg_do )&
              pre_dcfg_do=
    fi
    msg $m "deconfiguring $dev"
    #
    # terminate any other netlink/dhcp_client daemons and de-configure
    ifrc_stop_netlink_daemon 
    ifrc_stop_dhcp_client 
    ifconfig $dev 0.0.0.0 2>/dev/null \
    || msg "  ...deconfig for dn_action resulting in error, ignored"
    ##
    if [ -n "$post_dcfg_do" ]
    then
      msg "   post_dcfg_do"
      ( eval $post_dcfg_do )&
              post_dcfg_do=
    fi
    exit 0
    ;;

  stop|start|restart) ## act on init/driver, does not return
    exec /etc/init.d/S??network* $devalias $IFRC_ACTION
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
      ccl=`cat /sys/class/net/$dev/carrier 2>/dev/null`
      [ "$ccl" != "1" ] && ccl="no carrier/cable/link" || ccl="linked"

      iw dev $dev link |grep -q Connected \
      && ccl="$ccl, associated"

      ps |grep -q ifplug[d].*$dev && ccl="managed, $ccl" 

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
    [ -n "${v:0:1}" ] \
    && ps -o pid,args |grep -E "dhc[pl]|ifplug[d]" |grep "$dev"
    #&& ps -o pid,args |grep -v grep |grep "$dev"
    echo
    exit 0
    ;;

  status) ## check if iface is configured and show its ip-address
    ## confirm configured <iface>: [ip-address]:0/1
    ip=$( ifconfig $dev 2>/dev/null |sed -n 's/\ *inet addr:\([0-9.]*\) .*/\1/p' )
    [ -n "$ip" ] && { msg $ip; exit 0; } || exit 1
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

  *) ## usage, does not return
    usage ~1."invalid action specified"
    ;;
esac

# interface is not managed for method-manual or localhost
[ "$IFRC_METHOD" == "manual" ] && ifnl_disable=.
[ "$dev" == "lo" ] && ifnl_disable=.

#
# The rest of this script handles the configuration of an interface.
# And is run when called again manually, or via the netlink daemon.
# So, the first step is to ensure that netlink is active for <interface>.
if [ -n "$ifnl_disable" ]
then
  echo "  ...ifnl_disable"
  ifrc_stop_netlink_daemon
else
  ifplugd="ifplugd -s -q -p -a -f -d 1 -M -r /etc/network/ifrc.sh -i $dev"
  ps \
    |grep -q "ifplug[d].*${dev}" \
    && echo "  ...ifplugd running" \
    || {
      #msg "netlink support not active, starting ifplugd in background..."
      #msg "method: $IFRC_METHOD $IFRC_METHOD_PARAMS"
      # If ifrc.sh exits with non-zero status, then ifplugd will not daemonize.
      # Only exit non-zero for permanent conditions that prevent configuration.
      ( $ifplugd )&
      ifplugd_pid=$!
      printf "% 5d %s\n" $ifplugd_pid "$ifplugd" >>$ifrc_Log
      echo "$ifplugd_pid ifplugd started"
      usleep 400000
      #ps \
      #  |grep -q "ifplug[d].*${dev}" \
      #  || {
      #    echo -e "\t...ifplugd failed to daemonize" >>$ifrc_Log
      #    ifplugd_=.
      #  }
    }
fi

# wait until there is a link associated, for wifi.
grep -q $dev /proc/net/wireless 2>/dev/null && {
  link=`sed -n "s/${dev}: [0-9]*[ ]*\([0-9]*\).*/\1/p" \
      /proc/net/wireless 2>/dev/null`

  [ -n "$link" ] && [ $link -gt 0 ] \
  || {
    if [ "$IFRC_METHOD" == "dhcp" ]
    then
      msg "not associated, deferring..."
      exit 0
    fi
  }
}

# defer to netlink daemon
[ -n "$ifplugd_" ] && exit 0
[ -n "$ifrc_Wait" ] && exit 0

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
# $( if ifconfig <iface> 2>/dev/null |grep -q inet; then true; fi )
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
  for x in $IFRC_METHOD_PARAMS
  do
    echo $x |grep -q "[iats][a-z]*=[0-9].*" \
    || { msg "ignoring invalid extra parameter: $x"; continue; }
    case $x in
      ip=*|address=*) ## specify ip to request from server
        ip=${x##*=}
        rip="--request $ip"
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
}

ipa=
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

rip=
run_udhcpc()
{
  [ -z "$v" ] && nv='|grep -E "obtained|udhcpc"'
  [ "${v:0:1}" == "." ] && q=
  [ "${v:1:1}" == "." ] && vb='-v' 

  #ifrc_stop_dhcp_client
  export udhcpc_=$vb

  # run until we get a lease or killed, request specific options
  # the conf file handles states and writes to a leases file
  eval \
  $T udhcpc $vb $rip -q -i $dev -t 4 -T 2 -A 5 -o $bf \
   -O lease \
   -O domain \
   -O dns \
   -O hostname \
   -O subnet \
   -O router \
   -O serverid \
   -O broadcast \
   -s /etc/dhcp/udhcpc.conf $nv
   
   # restart auto-negotiation after using fixed speed
#   [ -n "$fpsd" ] && [ -n "$mii" ] && $mii -r $dev >/dev/null
# well, restoring this has another side-effect...
# disabled for now, so the fpsd will remain in-effect
  #echo -en "$PS1"
  return 0
}

run_dhclient()
{
  #ifrc_stop_dhcp_client

  # don't run this critter as daemon, hard to kill
  # some issues not fully vetted, app contains dead code
  dhclient -d -v $dev \
   -pf /var/log/dhclient.$dev.pid \
    >/var/log/dhclient.$dev.log 2>&1
  
  return 0
}

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
    show_filtered_method_params $v
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
    show_filtered_method_params $v
    # configure interface <ip [+nm]>
    if [ -z "$ip" ]
    then
      msg "configuration in-complete, need at lease the ip"
      show_filtered_method_params -v
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
    show_filtered_method_params $v
    # requested ip
    [ -n "$rip" ] && msg $rip
    
    # need a link beat in order for dhcp to work
    # so try waiting up to 5s, and double check this tricky indicator
    touch /tmp/ifrc.$dev.lbto
    let lbto=5000
    let n=0
    while [ $n -lt $lbto -a -f /tmp/ifrc.$dev.lbto ]
    do
      grep -q 1 /sys/class/net/${dev}/carrier && break
      usleep 200000 && let n+=200
    done
    rm -f /tmp/ifrc.$dev.lbto
    if ! grep -q 1 /sys/class/net/${dev}/carrier
    then
      msg "  ...no carrier/cable/link, deferring (to await link)"
      # we want to defer configuration for now...
      exit 0
    fi
    [ $n -gt 0 ] && msg "  waited ${n}ms on ${dev}/carrier"

    # allow using a fixed-port-speed-duplex, intended only for wired ports
    if ! grep -q $dev /proc/net/wireless && [ -n "$mii" ]
    then
      [ -n "$fpsd" ] \
      && $mii -F $fpsd $dev 2>&1 |grep "[vb]a[ls][ue]" 
    fi

    ## maybe allow way to select favored client, dhclient has issues tho...
    # need to add governor to limit futile requests
  # ( run_dhclient )&
    ( run_udhcpc )&
    sleep 1
    echo -en \\\r 

    if [ -n "$to" ]
    then
      # wait for ip-address and exit non-zero if timeout...  
      # there will not be any automatic restart nor netlink event
      #msg "using timeout of $to seconds"
      while [ $to -gt 0 ]
      do
        [ "${v:0:1}" == "." ] && echo -en .
        sleep 1
        let to-=1
        gipa && { to=; break; }
      done
      [ "${v:0:1}" == "." ] && echo
      if [ -n "$to" ]
      then
        ifrc_stop_dhcp_client
        msg "  ...no dhcp offer, timeout (error)"
        exit 1;
      fi
    fi
    ;;
  
  *)
    msg "unhandled, configuration method: ${IFRC_METHOD} (error)"
    exit 1
    ;;
esac
#
# Can only get to this point if we successfully (re-)up'd the interface,
# and it should be packet-ready. If using dhcp, then must employ timeout.
#
if [ -n "$post_cfg_do" ]
then
  msg "   post_cfg_do"
  ( eval $post_cfg_do )&
          post_cfg_do=
fi
exit 0 
