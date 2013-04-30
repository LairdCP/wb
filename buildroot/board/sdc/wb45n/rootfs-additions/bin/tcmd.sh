#!/bin/sh
# tcmd.sh - setup for using athtestcmd
# jon.hefling@lairdtech.com


# For normal wifi operation, we use latest firmware, which requires a symlink.
#
FW_LINK=/lib/firmware/ath6k/AR6003/hw2.1.1/fw-4.bin
FIRMWARE=fw_v3.4.0.62.bin

do_() {
  echo -e "#\n# $@" && $@
}


case $1 in
  \?|-h|--help)
    echo "Use to set firmware for normal or testmode (for athtestcmd usage)."
    echo "Run this script w/o args to simply (re)setup for athtestcmd."
    echo 
    echo "Options:"
    echo "  normal - set normal wifi operation"
    echo "  testmode - set up for athtestcmd"
    echo 
    echo "Usage:"
    echo "  $0 [option]"
    echo 
    ;;
  '') ## setup for athtestcmd
    [ -x /usr/bin/athtestcmd ] || { echo error; exit 1; }
    #
    rmmod ath6kl_sdio 2>/dev/null
    rmmod ath6kl_core 2>/dev/null
    echo setting up for athtestcmd
    (
      cd /lib/modules/`uname -r`/kernel/drivers/net/wireless/ath/ath6kl
      insmod ath6kl_core.ko testmode=1
      insmod ath6kl_sdio.ko
    )
    echo /sys/class/net/wlan0: \
    && cat /sys/class/net/wlan0/uevent \
    && cat /sys/class/net/wlan0/device/uevent \
    || { echo wlan# device n/a; exit 1; }
    do_ athtestcmd -i wlan0 --otpdump
    #do_ athtestcmd -i wlan0 --rx promis --rxfreq 2417 --rx antenna auto
    #do_ athtestcmd -i wlan0 --rx report --rxfreq 2417 --rx antenna auto
    ;;
  normal) ## restore wifi
    echo "restoring normal wifi setup..."
    # restore firmware symlink for normal operation
    ln -sf ${FIRMWARE} ${FW_LINK} 
    # set /e/n/i option
    ifrc wlan0 auto
    wireless stop
    ;;
  testmode) ## setup for testing
    echo "setting up for athtestcmd..."
    # remove firmware symlink for testmode
    rm -f ${FW_LINK}
    # unset /e/n/i option
    ifrc wlan0 noauto
    wireless stop
    ;;
  check) ## list firmware files
    ls -l ${FW_LINK%/*}
    ;;
esac

