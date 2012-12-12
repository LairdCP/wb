#!/bin/sh

set -e

wpa_psk() {
    SSID="$1"
    echo "*** $SSID '$2' '$3' ***"
    ( echo profile Default activate;
      echo profile $SSID delete;
      echo profile $SSID add;
      echo profile $SSID set ssid $SSID;
      echo profile $SSID set weptype "$2";
      echo profile $SSID set psk "$3";
      echo profile $SSID activate
    ) | sdc_cli
    echo sdc_cli done
}

wep() {
    SSID="$1"
    echo "*** "$@" ***"
    ( echo profile Default activate;
      echo profile $SSID delete;
      echo profile $SSID add;
      echo profile $SSID set ssid $SSID;
      echo profile $SSID set weptype "$2";
      [ -n "$3" ] && echo profile $SSID set wep "$3" 1;
      [ -n "$4" ] && echo profile $SSID set wep "$4" 2;
      [ -n "$5" ] && echo profile $SSID set wep "$5" 3;
      [ -n "$6" ] && echo profile $SSID set wep "$6" 4;
      echo profile $SSID set wep tx $7;
      echo profile $SSID activate
    ) | tee WEP | sdc_cli
}

wpa_psk "summit-test" psk "we-test-till-we-drop"
