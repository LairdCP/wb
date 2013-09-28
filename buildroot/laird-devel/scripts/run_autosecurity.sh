#!/bin/sh

# per wb45n board variables
: ${BOARD_IP_ADDRESS:=10.1.44.161}

SSH="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
SCP="scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

# run the autosecurity script
sshpass -psummit $SSH root@$BOARD_IP_ADDRESS wireless stop
sshpass -psummit $SCP -r buildroot/laird-devel/scripts/certs/* root@$BOARD_IP_ADDRESS:/etc/ssl
sshpass -psummit $SCP buildroot/laird-devel/scripts/wfaXX.conf root@$BOARD_IP_ADDRESS:/etc/summit/profiles.conf
sshpass -psummit $SCP buildroot/laird-devel/scripts/autosecurity.sh root@$BOARD_IP_ADDRESS:/bin/
sshpass -psummit $SSH root@$BOARD_IP_ADDRESS <<EOF
ifrc wlan0 start
chmod a+x /bin/autosecurity.sh
/bin/autosecurity.sh
EOF
