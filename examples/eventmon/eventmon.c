#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>

#include "sdc_sdk.h"
#include "lrd_platspec.h"

void sigproc(int);
 
void quitproc(int); 

char BUFFER[20] = "                   ";

int testnum = 0;

char * eventToStr(int event)
{
    switch(event)
    {
        case SDC_E_SET_SSID: return "SDC_E_SET_SSID"; break;
        case SDC_E_AUTH: return "SDC_E_AUTH"; break;
        case SDC_E_AUTH_IND: return "SDC_E_AUTH_IND"; break;
        case SDC_E_DEAUTH: return "SDC_E_DEAUTH"; break;
        case SDC_E_DEAUTH_IND: return "SDC_E_DEAUTH_IND"; break;
        case SDC_E_ASSOC: return "SDC_E_ASSOC"; break;
        case SDC_E_ASSOC_IND: return "SDC_E_ASSOC_IND"; break;
        case SDC_E_REASSOC: return "SDC_E_REASSOC"; break;
        case SDC_E_REASSOC_IND: return "SDC_E_REASSOC_IND"; break;
        case SDC_E_DISASSOC: return "SDC_E_DISASSOC"; break;
        case SDC_E_DISASSOC_IND: return "SDC_E_DISASSOC_IND"; break;
        case SDC_E_QUIET_START: return "SDC_E_QUIET_START"; break;
        case SDC_E_QUIET_END: return "SDC_E_QUIET_END"; break;
        case SDC_E_BEACON_RX: return "SDC_E_BEACON_RX"; break;
        case SDC_E_MIC_ERROR: return "SDC_E_MIC_ERROR"; break;
        case SDC_E_ROAM: return "SDC_E_ROAM"; break;
        case SDC_E_PMKID_CACHE: return "SDC_E_PMKID_CACHE"; break;
        case SDC_E_ADDTS_IND: return "SDC_E_ADDTS_IND"; break;
        case SDC_E_DELTS_IND: return "SDC_E_DELTS_IND"; break;
        case SDC_E_ROAM_PREP: return "SDC_E_ROAM_PREP"; break;
        case SDC_E_PSM_WATCHDOG: return "SDC_E_PSM_WATCHDOG"; break;
        case SDC_E_PSK_SUP: return "SDC_E_PSK_SUP"; break;
        case SDC_E_ICV_ERROR: return "SDC_E_ICV_ERROR"; break;
        case SDC_E_RSSI: return "SDC_E_RSSI"; break;
        case SDC_E_DHCP: return "SDC_E_DHCP"; break;
		case SDC_E_READY:  return "SDC_E_READY"; break;
		case SDC_E_CONNECT_REQ:  return "SDC_E_CONNECT_REQ"; break;
		case SDC_E_CONNECT:  return "SDC_E_CONNECT"; break;
		case SDC_E_RECONNECT_REQ:  return "SDC_E_RECONNECT_REQ"; break;
		case SDC_E_DISCONNECT_REQ:  return "SDC_E_DISCONNECT_REQ"; break;
		case SDC_E_DISCONNECT:  return "SDC_E_DISCONNECT"; break;
		case SDC_E_SCAN_REQ:  return "SDC_E_SCAN_REQ"; break;
		case SDC_E_SCAN:  return "SDC_E_SCAN"; break;
		case SDC_E_REGDOMAIN:  return "SDC_E_REGDOMAIN"; break;
		case SDC_E_CMDERROR:  return "SDC_E_CMDERROR"; break;
        case SDC_E_MAX: return "SDC_E_MAX"; break;
	    default :
		    sprintf(BUFFER, "0x%x", event);
		    return BUFFER;
    }
}

/* Event status codes */
char * statusToStr( int status)
{
    switch(status)
    {
        case SDC_E_STATUS_SUCCESS : return "SDC_E_STATUS_SUCCESS"; break;
        case SDC_E_STATUS_FAIL : return " SDC_E_STATUS_FAIL"; break;
        case SDC_E_STATUS_TIMEOUT : return "SDC_E_STATUS_TIMEOUT"; break;
        case SDC_E_STATUS_NO_NETWORKS : return "SDC_E_STATUS_NO_NETWORKS"; break;
        case SDC_E_STATUS_ABORT : return "SDC_E_STATUS_ABORT"; break;
        case SDC_E_STATUS_NO_ACK : return "SDC_E_STATUS_NO_ACK"; break;
        case SDC_E_STATUS_UNSOLICITED : return "SDC_E_STATUS_UNSOLICITED"; break;
        case SDC_E_STATUS_ATTEMPT : return "SDC_E_STATUS_ATTEMPT"; break;
        case SDC_E_STATUS_PARTIAL : return "SDC_E_STATUS_PARTIAL"; break;
        case SDC_E_STATUS_NEWSCAN : return "SDC_E_STATUS_NEWSCAN"; break;
        case SDC_E_STATUS_NEWASSOC : return "SDC_E_STATUS_NEWASSOC"; break;
        case SDC_E_STATUS_11HQUIET : return "SDC_E_STATUS_11HQUIET"; break;
        case SDC_E_STATUS_SUPPRESS : return "SDC_E_STATUS_SUPPRESS"; break;
        case SDC_E_STATUS_NOCHANS : return "SDC_E_STATUS_NOCHANS"; break;
        case SDC_E_STATUS_CCXFASTRM : return "SDC_E_STATUS_CCXFASTRM"; break;
        case SDC_E_STATUS_CS_ABORT : return "SDC_E_STATUS_CS_ABORT"; break;
        default :
		    sprintf(BUFFER, "%d", status);
		    return BUFFER;
    }
}

char * roamReasonToStr( int reason )
{
    switch(reason)
    {
        case SDC_E_REASON_INITIAL_ASSOC : return "SDC_E_REASON_INITIAL_ASSOC"; break;
        case SDC_E_REASON_LOW_RSSI : return "SDC_E_REASON_LOW_RSSI"; break;
        case SDC_E_REASON_DEAUTH : return "SDC_E_REASON_DEAUTH"; break;
        case SDC_E_REASON_DISASSOC : return "SDC_E_REASON_DISASSOC"; break;
        case SDC_E_REASON_BCNS_LOST : return "SDC_E_REASON_BCNS_LOST"; break;
        case SDC_E_REASON_FAST_ROAM_FAILED : return "SDC_E_REASON_FAST_ROAM_FAILED"; break;
        case SDC_E_REASON_DIRECTED_ROAM : return "SDC_E_REASON_DIRECTED_ROAM"; break;
        case SDC_E_REASON_TSPEC_REJECTED : return "SDC_E_REASON_TSPEC_REJECTED"; break;
        case SDC_E_REASON_BETTER_AP : return "SDC_E_REASON_BETTER_AP"; break;
    	default :
		    sprintf(BUFFER, "%d", reason);
		    return BUFFER;
    }
}

char * w80211ReasonToStr(reason)
{
    switch(reason)
    {
        case DOT11_RC_RESERVED		    : return "DOT11_RC_RESERVED"; break;	
        case DOT11_RC_UNSPECIFIED	    : return "DOT11_RC_UNSPECIFIED"; break;
        case DOT11_RC_AUTH_INVAL		: return "DOT11_RC_AUTH_INVAL"; break;
        case DOT11_RC_DEAUTH_LEAVING	: return "DOT11_RC_DEAUTH_LEAVING"; break;	
        case DOT11_RC_INACTIVITY		: return "DOT11_RC_INACTIVITY"; break;
        case DOT11_RC_BUSY			    : return "DOT11_RC_BUSY"; break;
        case DOT11_RC_INVAL_CLASS_2		: return "DOT11_RC_INVAL_CLASS_2"; break;
        case DOT11_RC_INVAL_CLASS_3		: return "DOT11_RC_INVAL_CLASS_3"; break;
        case DOT11_RC_DISASSOC_LEAVING	: return "DOT11_RC_DISASSOC_LEAVING"; break;
        case DOT11_RC_NOT_AUTH		    : return "DOT11_RC_NOT_AUTH"; break;
        case DOT11_RC_BAD_PC			: return "DOT11_RC_BAD_PC"; break;
        case DOT11_RC_BAD_CHANNELS		: return "DOT11_RC_BAD_CHANNELS"; break;
        case DOT11_RC_UNSPECIFIED_QOS	: return "DOT11_RC_UNSPECIFIED_QOS"; break;
        case DOT11_RC_INSUFFCIENT_BW	: return "DOT11_RC_INSUFFCIENT_BW"; break;
        case DOT11_RC_EXCESSIVE_FRAMES	: return "DOT11_RC_EXCESSIVE_FRAMES"; break;
        case DOT11_RC_TX_OUTSIDE_TXOP	: return "DOT11_RC_TX_OUTSIDE_TXOP"; break;
        case DOT11_RC_LEAVING_QBSS		: return "DOT11_RC_LEAVING_QBSS"; break;
        case DOT11_RC_BAD_MECHANISM		: return "DOT11_RC_BAD_MECHANISM"; break;
        case DOT11_RC_SETUP_NEEDED		: return "DOT11_RC_SETUP_NEEDED"; break;
        case DOT11_RC_TIMEOUT		    : return "DOT11_RC_TIMEOUT"; break;
        case DOT11_RC_INVALID_WPA_IE    : return "DOT11_RC_INVALID_WPA_IE"; break;
        case DOT11_RC_MIC_FAILURE		: return "DOT11_RC_MIC_FAILURE"; break;
        case DOT11_RC_4WH_TIMEOUT		: return "DOT11_RC_4WH_TIMEOUT"; break;
        case DOT11_RC_GTK_UPDATE_TIMEOUT: return "DOT11_RC_GTK_UPDATE_TIMEOUT"; break;
        case DOT11_RC_WPA_IE_MISMATCH	: return "DOT11_RC_WPA_IE_MISMATCH"; break;
        case DOT11_RC_INVALID_MC_CIPHER	: return "DOT11_RC_INVALID_MC_CIPHER"; break;
        case DOT11_RC_INVALID_UC_CIPHER	: return "DOT11_RC_INVALID_UC_CIPHER"; break;
        case DOT11_RC_INVALID_AKMP		: return "DOT11_RC_INVALID_AKMP"; break;
        case DOT11_RC_BAD_WPA_VERSION	: return "DOT11_RC_BAD_WPA_VERSION"; break;
        case DOT11_RC_INVALID_WPA_CAP	: return "DOT11_RC_INVALID_WPA_CAP"; break;
        case DOT11_RC_8021X_AUTH_FAIL	: return "DOT11_RC_8021X_AUTH_FAIL"; break;
        default :
		    sprintf(BUFFER, "%d", reason);
		    return BUFFER;
    }
}

char * disconnectReasontoStr(reason)
{
    switch(reason)
    {
        case NO_NETWORK_AVAIL		: return "NO_NETWORK_AVAIL"; break;	
        case LOST_LINK	    		: return "LOST_LINK"; break;
        case DISCONNECT_CMD			: return "DISCONNECT_CMD"; break;
        case BSS_DISCONNECTED		: return "BSS_DISCONNECTED"; break;	
        case AUTH_FAILED			: return "AUTH_FAILED"; break;
        case ASSOC_FAILED			: return "ASSOC_FAILED"; break;
        case NO_RESOURCES_AVAIL		: return "NO_RESOURCES_AVAIL"; break;
		case CSERV_DISCONNECT		: return "CSERV_DISCONNECT"; break;
        case INVALID_PROFILE		: return "INVALID_PROFILE"; break;
        case DOT11H_CHANNEL_SWITCH	: return "DOT11H_CHANNEL_SWITCH"; break;
        case PROFILE_MISMATCH		: return "PROFILE_MISMATCH"; break;
        case CONNECTION_EVICTED		: return "CONNECTION_EVICTED"; break;
        case IBSS_MERGE				: return "IBSS_MERGE"; break;
        default :
		    sprintf(BUFFER, "%d", reason);
		    return BUFFER;
    }
}

char * authModeToStr( int auth_type )
{
    switch(auth_type)
    {
        case AUTH_OPEN : return "AUTH_OPEN"; break;
        case AUTH_SHARED : return "AUTH_SHARED"; break;
        case AUTH_NETWORK_EAP : return "AUTH_NETWORK_EAP"; break;
    	default :
		    sprintf(BUFFER, "%d", auth_type);
		    return BUFFER;
    }
}

char *ether_ntoa(const sdc_ether_addr *ea, char *buf)
{
	static const char template[] = "%02x:%02x:%02x:%02x:%02x:%02x";
	snprintf(buf, 18, template,
		ea->octet[0]&0xff, ea->octet[1]&0xff, ea->octet[2]&0xff,
		ea->octet[3]&0xff, ea->octet[4]&0xff, ea->octet[5]&0xff);
	return (buf);
}

unsigned long long historic_bitmask = 0;

SDCERR event_handler(unsigned long event_type, SDC_EVENT *event)
{
	DHCP_LEASE dhcp;
	printf("Test number: %d\n", testnum++);
    historic_bitmask |= (1 << event_type);
    //event/status 
    printf("event: %s\tstatus: %s\n", eventToStr(event_type), statusToStr(event->status));
    //reason
    switch (event_type)
    {
        case SDC_E_ROAM : 
            printf("\tRoam reason: %s\n", roamReasonToStr(event->reason));
            break;
        case SDC_E_AUTH :
        case SDC_E_AUTH_IND :
        case SDC_E_DEAUTH :
        case SDC_E_DEAUTH_IND :
        case SDC_E_ASSOC :
        case SDC_E_ASSOC_IND :
        case SDC_E_REASSOC :
        case SDC_E_REASSOC_IND :
        case SDC_E_DISASSOC :
        case SDC_E_DISASSOC_IND :
        case SDC_E_QUIET_START :
        case SDC_E_QUIET_END :
            if(event->reason)
                printf("\t80211 reason: %s\n", w80211ReasonToStr(event->reason));     
			break;
		case SDC_E_DISCONNECT :
			if(event->reason)
				printf("\tDisconnect reason: %s\n", disconnectReasontoStr(event->reason));
			break;
		case SDC_E_DHCP:
			PLAT_GetDHCPInfo(&dhcp);
			PLAT_PrintDHCPInfo(&dhcp);	
			break;
    }
    // auth_type
    switch(event_type)
    {
        case SDC_E_AUTH :
        case SDC_E_AUTH_IND :
		case SDC_E_CONNECT_REQ :
            printf("\tAuth type: %s\n", authModeToStr(event->auth_type));
            break;
        default:
            break;
    }
    
    sdc_ether_addr *ea=&event->addr;
    // ether_addr
    if (ea->octet[0] | ea->octet[1] | ea->octet [2] |
        ea->octet[3] | ea->octet[4] | ea->octet [5])
    {
        ether_ntoa(ea, BUFFER);
        printf("\taddress: %s\n", BUFFER);
    }
    return(SDCERR_SUCCESS);
}

int main()
{
    unsigned long long bitmask =0;
    int i, rc;
      
    signal(SIGINT, sigproc);
    signal(SIGQUIT, quitproc);

    for (i=(int)SDC_E_SET_SSID; i< SDC_E_MAX; i++)
    {
        bitmask |= (1<<i);
    }
    bitmask = 0xFFFFFFFFFFFFFFFF;

    rc = SDCRegisterForEvents( bitmask, event_handler);
    
    printf("RegisterForEvents rc 0x%x\n", rc);
    printf("Registered Bitmask 0x%016llX\n", bitmask);

    SDCRegisteredEventsList(&bitmask);
    printf("Registered Bitmask 0x%016llX\n", bitmask);

   // sleep forever.  Exit via control-c
   for(;;)
        sleep(1);

    return (0);
}

void dumpBitmaskAndExit(unsigned long long bitmask)
{
    int i;
    if(!bitmask)
    {
        printf("\nNo events reported\n");
    }
    printf("\nBitmask of events which occured: 0x%016llX\n", bitmask);
    printf("Events:\n");
    for (i=0; i < 8*sizeof(bitmask); i++)
    {
        if ((1<<i) & bitmask)
            printf("%s\n",eventToStr(i));
    }
}

void sigproc(int foo)
{ 	
    SDCDeregisterEvents();
    dumpBitmaskAndExit(historic_bitmask);
    exit(0);
}
 
void quitproc(int foo)
{
    SDCDeregisterEvents();
    dumpBitmaskAndExit(historic_bitmask);
    exit(0);
}
