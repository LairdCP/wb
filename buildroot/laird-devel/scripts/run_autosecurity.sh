#!/bin/sh

# per wb45n board variables
: ${WB45N_ADDRESS:=10.1.44.161}

SSH="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
SCP="scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

# run the autosecurity script
sshpass -psummit $SSH root@$WB45N_ADDRESS wireless stop
sleep 2
sshpass -psummit $SCP -r buildroot/laird-devel/scripts/certs/* root@$WB45N_ADDRESS:/etc/ssl
sshpass -psummit $SCP buildroot/laird-devel/scripts/wfaXX.conf root@$WB45N_ADDRESS:/etc/summit/profiles.conf
sshpass -psummit $SCP buildroot/laird-devel/scripts/autosecurity.sh root@$WB45N_ADDRESS:/bin/
sshpass -psummit $SSH root@$WB45N_ADDRESS <<EOF
ifrc wlan0 up
chmod a+x /bin/autosecurity.sh
autosecurity.sh
EOF
