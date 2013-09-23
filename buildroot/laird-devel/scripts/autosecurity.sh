#PROFILE VARIABLES

set -e -x

RMODE=ABG 		#B,BG,G,A,ABG,BGA
BRATE="0" 		#0-Auto,1,2,5.5,6,9,11,12,18,24,36,48,54
PSAVE=off 		#off/fast/max
TPOWER="0" 		#0-Max, 1,5,10,20,30,50
RadioEnable="1" #0-off 1-on; this will enable the radio after config is done
alias ip="ifconfig wlan0 | grep 'inet addr:' | awk -F: '{print $2}' | awk '{print $1}'"
alias link='echo `iw dev wlan0 link`'

IPCHECK(){			
	BLANK=
	ADDR=
	WAIT=1
	while [ `ip | wc -c` -lt 7 ]
	do
		echo -en "Waiting on IP address($WAIT Seconds) \n"
		WAIT=`expr $WAIT + 1`
		sleep 1
		if [ $WAIT -ge "61" ]
			then
			echo "DHCP timeout reached for wfa$COUNT 	"
			exit 1
		fi
	done
	if [ `link | wc -c` -lt 16 ]
		then
		echo "$TEST: Wfa$COUNT is not connected to an AP"
		exit 1
	elif [ `ip | wc -c` -lt 7 ]
		then
		echo "$TEST: Wfa$COUNT did not recieve a IP address"
		exit 1
	else
		echo "Received IP address:`ip`"
		echo "Downloading the test file" 
		wget --bind-address=10.1.44.171 -O /tmp/test.file      http://10.1.44.227/scratch/test.file
		wget --bind-address=10.1.44.171 -O /tmp/test.file.sha1 http://10.1.44.227/scratch/test.file.sha1
		(cd /tmp && sha1sum test.file > /tmp/test.file.sha1_)
		rm /tmp/test.file
		diff /tmp/test.file.sha1 /tmp/test.file.sha1_ || exit 1
    fi
}

OPENWEPTEST(){
TEST=Open_WEP
echo "This will test wfa2, 3 for open WEP"
for COUNT in 2 3
	do
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set authtype open > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2
		IPCHECK
		
	done	
}
SHAREDWEPTEST() {
TEST=Shared_WEP
echo "This will test wfa2, 3 for shared WEP"
for COUNT in 2 3
	do	
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set authtype shared > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2		
		IPCHECK

	done	
}
PSKTEST(){	
TEST=PSK
echo "This will test wfa7, 9, 11, 13 for PSK"
for COUNT in 7 9 11 13
	do	
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2		
		IPCHECK

	done	
}
LEAPTEST(){ 	
TEST=LEAP
echo "This will test wfa4,8,10,12, and 14 for EAPTYPE LEAP"
for COUNT in 4 8 10 12 14
	do
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set eaptype leap > /dev/null
		sdc_cli profile wfa$COUNT set user user1 > /dev/null
		sdc_cli profile wfa$COUNT set password user1 > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2		
		IPCHECK
			
	done
}
FASTTEST(){	
TEST=EAP_FAST
echo "This will test wfa4,8,10,12, and 14 for EAPTYPE EAP-FAST"
for COUNT in 4 8 10 12 14
	do
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set eaptype eap-fast > /dev/null
		sdc_cli profile wfa$COUNT set user user1 > /dev/null
		sdc_cli profile wfa$COUNT set password user1 > /dev/null
		sdc_cli profile wfa$COUNT set pacfilename user1.pac > /dev/null
		sdc_cli profile wfa$COUNT set pacpassword user1 > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2	
		IPCHECK
			
	done			
}
MSCHAPTEST(){	
TEST=PEAP_MSCHAP
echo "This will test wfa4,8,10,12, and 14 for EAPTYPE PEAP-MSCHAP"
for COUNT in 4 8 10 12 14
	do
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set eaptype peap-mschap > /dev/null
		sdc_cli profile wfa$COUNT set user user1 > /dev/null
		sdc_cli profile wfa$COUNT set password user1 > /dev/null
		sdc_cli profile wfa$COUNT set cacert AkronCA.cer > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2		
		IPCHECK
			
	done			
}
GTCTEST(){		
TEST=PEAP_GTC
echo "This will test wfa4,8,10,12, and 14 for EAPTYPE PEAP-GTC"
for COUNT in 4 8 10 12 14
	do
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set eaptype peap-gtc > /dev/null
		sdc_cli profile wfa$COUNT set user user1 > /dev/null
		sdc_cli profile wfa$COUNT set password user1 > /dev/null
		sdc_cli profile wfa$COUNT set cacert AkronCA.cer > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2		
		IPCHECK
			
	done			
}
EAPTLSTEST(){	
TEST=EAP_TLS
echo "This will test wfa4,8,10,12, and 14 for EAPTYPE EAP-TLS"
for COUNT in 4 8 10 12 14
	do
		
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set eaptype eap-tls > /dev/null
		sdc_cli profile wfa$COUNT set user user1 > /dev/null
		sdc_cli profile wfa$COUNT set usercert user1.pfx > /dev/null
		sdc_cli profile wfa$COUNT set usercert_password user1 > /dev/null
		sdc_cli profile wfa$COUNT set cacert AkronCA.cer > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2		
		IPCHECK
		
	done			
}
PEAPTLSTEST(){
TEST=PEAP_TLS
echo "This will test wfa4,8,10,12, and 14 for EAPTYPE PEAP-TLS"
for COUNT in 4 8 10 12 14
	do
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set eaptype peap-tls > /dev/null
		sdc_cli profile wfa$COUNT set user user1 > /dev/null
		sdc_cli profile wfa$COUNT set usercert user1.pfx > /dev/null
		sdc_cli profile wfa$COUNT set usercert_password user1 > /dev/null
		sdc_cli profile wfa$COUNT set cacert AkronCA.cer > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2		
		IPCHECK
			
	done			
}
EAPTTLSTEST(){	
TEST=EAP_TTLS
echo "This will test wfa15,16,17,18 and 19 for EAPTYPE EAP-TTLS"
for COUNT in 15 16 17 18 19
	do
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set eaptype eap-ttls > /dev/null
		sdc_cli profile wfa$COUNT set user user1 > /dev/null
		sdc_cli profile wfa$COUNT set password user1 > /dev/null
		sdc_cli profile wfa$COUNT set cacert AkronCA.cer > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2
		IPCHECK
			
	done			
}

echo "Now testing CCX features"
##CCKM TESTING TKIP
CCKMTKIPFASTTEST(){	
TEST=CCKM_TKIP_EAP_FAST
echo "This will test wfa8 for EAPTYPE EAP-FAST CCKM"
for COUNT in 8
	do
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set weptype cckm-tkip > /dev/null
		sdc_cli profile wfa$COUNT set eaptype eap-fast > /dev/null
		sdc_cli profile wfa$COUNT set user user1 > /dev/null
		sdc_cli profile wfa$COUNT set password user1 > /dev/null
		sdc_cli profile wfa$COUNT set pacfilename user1.pac > /dev/null
		sdc_cli profile wfa$COUNT set pacpassword user1 > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2	
		IPCHECK
			
	done		
	
	sdc_cli profile Default activate > /dev/null		
}
CCKMTKIPLEAPTEST(){ 	
TEST=CCKM_TKIP_LEAP
echo "This will test wfa8 for EAPTYPE LEAP CCKM"
for COUNT in 8 
	do
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set weptype cckm-tkip > /dev/null
		sdc_cli profile wfa$COUNT set eaptype leap > /dev/null
		sdc_cli profile wfa$COUNT set user user1 > /dev/null
		sdc_cli profile wfa$COUNT set password user1 > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2		
		IPCHECK
			
	done
	
	sdc_cli profile Default activate > /dev/null
}
CCKMTKIPMSCHAPTEST(){	
TEST=CCKM_TKIP_PEAP_MSCHAP
echo "This will test wfa8 for EAPTYPE PEAP-MSCHAP CCKM"
for COUNT in 8
	do
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set weptype cckm-tkip > /dev/null
		sdc_cli profile wfa$COUNT set eaptype peap-mschap > /dev/null
		sdc_cli profile wfa$COUNT set user user1 > /dev/null
		sdc_cli profile wfa$COUNT set password user1 > /dev/null
		sdc_cli profile wfa$COUNT set cacert AkronCA.cer > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2		
		IPCHECK
			
	done			
	
	sdc_cli profile Default activate > /dev/null			
}
CCKMTKIPGTCTEST(){		
TEST=CCKM_TKIP_PEAP_GTC
echo "This will test wfa8 for EAPTYPE PEAP-GTC CCKM"
for COUNT in 8
	do
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set weptype cckm-tkip > /dev/null
		sdc_cli profile wfa$COUNT set eaptype peap-gtc > /dev/null
		sdc_cli profile wfa$COUNT set user user1 > /dev/null
		sdc_cli profile wfa$COUNT set password user1 > /dev/null
		sdc_cli profile wfa$COUNT set cacert AkronCA.cer > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2		
		IPCHECK
			
	done				
	
	sdc_cli profile Default activate > /dev/null		
}
CCKMTKIPEAPTLSTEST(){	
TEST=CCKM_TKIP_EAP_TLS
echo "This will test wfa8 for EAPTYPE EAP-TLS CCKM"
for COUNT in 8
	do
		
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set weptype cckm-tkip > /dev/null
		sdc_cli profile wfa$COUNT set eaptype eap-tls > /dev/null
		sdc_cli profile wfa$COUNT set user user1 > /dev/null
		sdc_cli profile wfa$COUNT set usercert user1.pfx > /dev/null
		sdc_cli profile wfa$COUNT set usercert_password user1 > /dev/null
		sdc_cli profile wfa$COUNT set cacert AkronCA.cer > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2		
		IPCHECK
		
	done			
	
	sdc_cli profile Default activate > /dev/null			
}
CCKMTKIPPEAPTLSTEST(){
TEST=CCKM_TKIP_PEAP_TLS
echo "This will test wfa8 for EAPTYPE PEAP-TLS CCKM"
for COUNT in 8
	do
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set weptype cckm-tkip > /dev/null
		sdc_cli profile wfa$COUNT set eaptype peap-tls > /dev/null
		sdc_cli profile wfa$COUNT set user user1 > /dev/null
		sdc_cli profile wfa$COUNT set usercert user1.pfx > /dev/null
		sdc_cli profile wfa$COUNT set usercert_password user1 > /dev/null
		sdc_cli profile wfa$COUNT set cacert AkronCA.cer > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2		
		IPCHECK
			
	done				
	
	sdc_cli profile Default activate > /dev/null		
}
CCKMTKIPEAPTTLSTEST(){	
TEST=CCKM_TKIP_EAP_TTLS
echo "This will test wfa18 for EAPTYPE EAP-TTLS CCKM"
for COUNT in 18
	do
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set weptype cckm-tkip > /dev/null
		sdc_cli profile wfa$COUNT set eaptype eap-ttls > /dev/null
		sdc_cli profile wfa$COUNT set user user1 > /dev/null
		sdc_cli profile wfa$COUNT set password user1 > /dev/null
		sdc_cli profile wfa$COUNT set cacert AkronCA.cer > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2
		IPCHECK
			
	done			
	
	sdc_cli profile Default activate > /dev/null			
}

##CCKM TESTING AES
CCKMAESFASTTEST(){	
TEST=CCKM_AES_EAP_FAST
echo "This will test wfa10 for EAPTYPE EAP-FAST CCKM"
for COUNT in 10
	do
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set weptype cckm-aes > /dev/null
		sdc_cli profile wfa$COUNT set eaptype eap-fast > /dev/null
		sdc_cli profile wfa$COUNT set user user1 > /dev/null
		sdc_cli profile wfa$COUNT set password user1 > /dev/null
		sdc_cli profile wfa$COUNT set pacfilename user1.pac > /dev/null
		sdc_cli profile wfa$COUNT set pacpassword user1 > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2	
		IPCHECK
			
	done			
	
	sdc_cli profile Default activate > /dev/null			
}
CCKMAESLEAPTEST(){ 	
TEST=CCKM_AES_LEAP
echo "This will test wfa10 for EAPTYPE LEAP CCKM"
for COUNT in 10 
	do
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set weptype cckm-aes > /dev/null
		sdc_cli profile wfa$COUNT set eaptype leap > /dev/null
		sdc_cli profile wfa$COUNT set user user1 > /dev/null
		sdc_cli profile wfa$COUNT set password user1 > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2		
		IPCHECK
			
	done		
	
	sdc_cli profile Default activate > /dev/null	
}
CCKMAESMSCHAPTEST(){	
TEST=CCKM_AES_PEAP_MSCHAP
echo "This will test wfa10 for EAPTYPE PEAP-MSCHAP CCKM"
for COUNT in 10
	do
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set weptype cckm-aes > /dev/null
		sdc_cli profile wfa$COUNT set eaptype peap-mschap > /dev/null
		sdc_cli profile wfa$COUNT set user user1 > /dev/null
		sdc_cli profile wfa$COUNT set password user1 > /dev/null
		sdc_cli profile wfa$COUNT set cacert AkronCA.cer > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2		
		IPCHECK
			
	done			
	
	sdc_cli profile Default activate > /dev/null			
}
CCKMAESGTCTEST(){		
TEST=CCKM_AES_PEAP_GTC
echo "This will test wfa10 for EAPTYPE PEAP-GTC CCKM"
for COUNT in 10
	do
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set weptype cckm-aes > /dev/null
		sdc_cli profile wfa$COUNT set eaptype peap-gtc > /dev/null
		sdc_cli profile wfa$COUNT set user user1 > /dev/null
		sdc_cli profile wfa$COUNT set password user1 > /dev/null
		sdc_cli profile wfa$COUNT set cacert AkronCA.cer > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2		
		IPCHECK
			
	done			
	
	sdc_cli profile Default activate > /dev/null			
}
CCKMAESEAPTLSTEST(){	
TEST=CCKM_AES_EAP_TLS
echo "This will test wfa10 for EAPTYPE EAP-TLS CCKM"
for COUNT in 10
	do
		
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set weptype cckm-aes > /dev/null
		sdc_cli profile wfa$COUNT set eaptype eap-tls > /dev/null
		sdc_cli profile wfa$COUNT set user user1 > /dev/null
		sdc_cli profile wfa$COUNT set usercert user1.pfx > /dev/null
		sdc_cli profile wfa$COUNT set usercert_password user1 > /dev/null
		sdc_cli profile wfa$COUNT set cacert AkronCA.cer > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2		
		IPCHECK
		
	done			
	
	sdc_cli profile Default activate > /dev/null			
}
CCKMAESPEAPTLSTEST(){
TEST=CCKM_AES_PEAP_TLS
echo "This will test wfa10 for EAPTYPE PEAP-TLS CCKM"
for COUNT in 10
	do
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set weptype cckm-aes > /dev/null
		sdc_cli profile wfa$COUNT set eaptype peap-tls > /dev/null
		sdc_cli profile wfa$COUNT set user user1 > /dev/null
		sdc_cli profile wfa$COUNT set usercert user1.pfx > /dev/null
		sdc_cli profile wfa$COUNT set usercert_password user1 > /dev/null
		sdc_cli profile wfa$COUNT set cacert AkronCA.cer > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2		
		IPCHECK
			
	done		
	
	sdc_cli profile Default activate > /dev/null				
}
CCKMAESEAPTTLSTEST(){	
TEST=CCKM_AES_EAP_TTLS
echo "This will test wfa19 for EAPTYPE EAP-TTLS CCKM"
for COUNT in 19
	do
		sdc_cli profile wfa$COUNT set mode $RMODE > /dev/null
		sdc_cli profile wfa$COUNT set bitrate $BRATE > /dev/null
		sdc_cli profile wfa$COUNT set powersave $PSAVE > /dev/null
		sdc_cli profile wfa$COUNT set txpower $TPOWER > /dev/null
		sdc_cli profile wfa$COUNT set weptype cckm-aes > /dev/null
		sdc_cli profile wfa$COUNT set eaptype eap-ttls > /dev/null
		sdc_cli profile wfa$COUNT set user user1 > /dev/null
		sdc_cli profile wfa$COUNT set password user1 > /dev/null
		sdc_cli profile wfa$COUNT set cacert AkronCA.cer > /dev/null
		sdc_cli profile wfa$COUNT activate > /dev/null
		if [ "$RadioEnable" == "1" ]
			then
				sdc_cli enable > /dev/null
		fi
		sleep 2
		IPCHECK
			
	done			
	
	sdc_cli profile Default activate > /dev/null			
}
run_test() {
	echo "********************************************************************"
	echo "* Starting Test: $1"
	echo "********************************************************************"
	"$1"
	echo "********************************************************************"
	echo "* Finished Test: $1"
	echo "********************************************************************"
}


echo "Radio Mode:$RMODE" | tee -a results.txt
echo "Bitrate:$BRATE" | tee -a results.txt
echo "Power Save:$PSAVE" | tee -a results.txt
echo "TX Power:$TPOWER" | tee -a results.txt
if [ "$RadioEnable" == "1" ]
	then
		echo "Enable Radio: on" | tee -a results.txt
	else
		echo "Enable Radio: off" | tee -a results.txt
fi


run_test OPENWEPTEST
run_test SHAREDWEPTEST
run_test PSKTEST
run_test LEAPTEST
run_test FASTTEST
run_test MSCHAPTEST
run_test GTCTEST
run_test EAPTLSTEST
run_test PEAPTLSTEST
run_test EAPTTLSTEST

if [ `sdc_cli global show | grep CCX | awk -F' ' '{ print $3 }'` == "off" ]
then
	echo "CCX features are off, not testing..."
else
	run_test CCKMTKIPFASTTEST
	run_test CCKMTKIPLEAPTEST
	run_test CCKMTKIPMSCHAPTEST
	run_test CCKMTKIPGTCTEST
	run_test CCKMTKIPEAPTLSTEST
	run_test CCKMTKIPPEAPTLSTEST
	run_test CCKMTKIPEAPTTLSTEST
	run_test CCKMAESFASTTEST
	run_test CCKMAESLEAPTEST
	run_test CCKMAESMSCHAPTEST
	run_test CCKMAESGTCTEST
	run_test CCKMAESEAPTLSTEST
	run_test CCKMAESPEAPTLSTEST
	run_test CCKMAESEAPTTLSTEST
fi

exit 0	
