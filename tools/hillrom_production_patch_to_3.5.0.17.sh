#!/bin/sh
# This script will create a patch to the 3.5.0.17 releaase. Hill-Rom required this patch
# to release their product. It lowers the TCP disconnects their software experienced.
# Expects 1 parameter, the WB's IP.

WB_IP=$1
NO_KEY_CHECK='-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'

#update to 3.5.0.30, which has the base files for the patch
sshpass -p summit ssh root@$WB_IP $NO_KEY_CHECK 'fw_update -xt -f http://10.1.40.199/builds/linux/wb45n/laird_fips/3.5.0.30/image/fw.txt'

#wait for WB to flash and restart
sleep 180

#find authTimeout in profiles.conf and set to 4
sshpass -p summit ssh root@$WB_IP $NO_KEY_CHECK 'sed -i 's/authTimeout=8/authTimeout=4/g' /etc/summit/profiles.conf'

#add a default profile that only contains the option for powersave off or CAM mode
sshpass -p summit ssh root@$WB_IP $NO_KEY_CHECK 'echo "[Comm\SDCCF10G1\Parms\Configs\DefaultConfigSettings]
PowerSave=0" >> /etc/summit/profiles.conf'

#remove the deconfig stage of the udhcpc.script
sshpass -p summit ssh root@$WB_IP $NO_KEY_CHECK 'sed -i '123d' /etc/dhcp/udhcpc.script'
sshpass -p summit ssh root@$WB_IP $NO_KEY_CHECK 'sed -i '125d' /etc/dhcp/udhcpc.script'

#now tar gzip everything up
sshpass -p summit ssh root@$WB_IP $NO_KEY_CHECK 'cd /;tar -cvzf hillrom_disconnect_ga3_fix.tar.gz etc/dhcp/udhcpc.script lib/firmware/ath6k/AR6003/hw2.1.1/fw-4.bin lib/firmware/ath6k/AR6003/hw2.1.1/fw_v3.4.0.86.bin usr/lib/libsdc_sdk.so.1.0 etc/summit/profiles.conf'

#copy the file to the local host
sshpass -p summit scp $NO_KEY_CHECK root@$WB_IP:/hillrom_disconnect_ga3_fix.tar.gz .

#create a script to do the extracting
cat > extract.sh <<'__END_SCRIPT__'
#!/bin/sh
# This is the self extracting patch for the Hill-Rom disconnect problem
# on Laird's 3.5.0.17 build
SKIP=`awk '/^__TARFILE_FOLLOWS__/ { print NR + 1; exit 0; }' $0`

#remember our file name
THIS=`pwd`/$0

cd /

# take the tarfile and pipe it into tar
tail -n +$SKIP $THIS | tar -xzv

echo "Finished"
exit 0

__TARFILE_FOLLOWS__
__END_SCRIPT__

#put the tarfile after the script and make it executable
cat extract.sh hillrom_disconnect_ga3_fix.tar.gz > hillrom_ga3_discon_fix.sh
chmod +x hillrom_ga3_discon_fix.sh
