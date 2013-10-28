#!/bin/sh

set -x

# per wb45n board variables
: ${BOARD_IP_ADDRESS:=10.16.196.45}

SSH="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
SCP="scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

# run the autotest script
sshpass -psummit $SCP buildroot/laird-devel/scripts/autotest.sh root@$BOARD_IP_ADDRESS:/bin/
sshpass -psummit $SSH root@$BOARD_IP_ADDRESS <<EOF
chmod a+x /bin/autotest.sh
/bin/autosecurity.sh
EOF
