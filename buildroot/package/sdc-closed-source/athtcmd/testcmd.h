/*
* Copyright (c) 2011-2012 Qualcomm Atheros Inc.
*
* Permission to use, copy, modify, and/or distribute this software for any
* purpose with or without fee is hereby granted, provided that the above
* copyright notice and this permission notice appear in all copies.
*
* THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
* WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
* MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
* ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
* WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
* ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
* OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
*/

#ifndef  TESTCMD_H_
#define  TESTCMD_H_

#include <stdint.h>

#ifdef AR6002_REV2
#define TCMD_MAX_RATES 12
#else
#define TCMD_MAX_RATES 28
#endif

#define PREPACK
#define POSTPACK __attribute__ ((packed))

#define ATH_MAC_LEN 6
#define TC_CMDS_SIZE_MAX  256

typedef enum {
	ZEROES_PATTERN = 0,
	ONES_PATTERN,
	REPEATING_10,
	PN7_PATTERN,
	PN9_PATTERN,
	PN15_PATTERN
} TX_DATA_PATTERN;

/* Continous tx
   mode : TCMD_CONT_TX_OFF - Disabling continous tx
          TCMD_CONT_TX_SINE - Enable continuous unmodulated tx
          TCMD_CONT_TX_FRAME- Enable continuous modulated tx
   freq : Channel freq in Mhz. (e.g 2412 for channel 1 in 11 g)
dataRate: 0 - 1 Mbps
          1 - 2 Mbps
          2 - 5.5 Mbps
          3 - 11 Mbps
          4 - 6 Mbps
          5 - 9 Mbps
          6 - 12 Mbps
          7 - 18 Mbps
          8 - 24 Mbps
          9 - 36 Mbps
         10 - 28 Mbps
         11 - 54 Mbps
  txPwr: Tx power in dBm[5 -11] for unmod Tx, [5-14] for mod Tx
antenna:  1 - one antenna
          2 - two antenna
Note : Enable/disable continuous tx test cmd works only when target is awake.
*/

typedef enum {
	TCMD_CONT_TX_OFF = 0,
	TCMD_CONT_TX_SINE,
	TCMD_CONT_TX_FRAME,
	TCMD_CONT_TX_TX99,
	TCMD_CONT_TX_TX100,
	TCMD_CONT_TX_OFFSETTONE,
} TCMD_CONT_TX_MODE;

typedef enum {
	TCMD_WLAN_MODE_NOHT = 0,
	TCMD_WLAN_MODE_HT20 = 1,
	TCMD_WLAN_MODE_HT40PLUS = 2,
	TCMD_WLAN_MODE_HT40MINUS = 3,
        TCMD_WLAN_MODE_CCK = 4,

        TCMD_WLAN_MODE_MAX,
        TCMD_WLAN_MODE_INVALID = TCMD_WLAN_MODE_MAX
} TCMD_WLAN_MODE;

typedef enum {
    TPC_TX_PWR = 0,
    TPC_FORCED_GAIN,
    TPC_TGT_PWR
} TPC_TYPE;

typedef PREPACK struct {
	uint32_t testCmdId;
	uint32_t mode;
	uint32_t freq;
	uint32_t dataRate;
	int32_t txPwr;
	uint32_t antenna;
	uint32_t enANI;
	uint32_t scramblerOff;
	uint32_t aifsn;
	uint16_t pktSz;
	uint16_t txPattern;
	uint32_t shortGuard;
	uint32_t numPackets;
	uint32_t wlanMode;
        uint32_t tpcm;
} POSTPACK TCMD_CONT_TX;

#define TCMD_TXPATTERN_ZERONE                 0x1
#define TCMD_TXPATTERN_ZERONE_DIS_SCRAMBLE    0x2

/* Continuous Rx
 act: TCMD_CONT_RX_PROMIS - promiscuous mode (accept all incoming frames)
      TCMD_CONT_RX_FILTER - filter mode (accept only frames with dest
                                             address equal specified
                                             mac address (set via act =3)
      TCMD_CONT_RX_REPORT  off mode  (disable cont rx mode and get the
                                          report from the last cont
                                          Rx test)

     TCMD_CONT_RX_SETMAC - set MacAddr mode (sets the MAC address for the
                                                 target. This Overrides
                                                 the default MAC address.)

*/
typedef enum {
	TCMD_CONT_RX_PROMIS = 0,
	TCMD_CONT_RX_FILTER,
	TCMD_CONT_RX_REPORT,
	TCMD_CONT_RX_SETMAC,
	TCMD_CONT_RX_SET_ANT_SWITCH_TABLE,
	TC_CMD_RESP,
	TCMD_CONT_RX_GETMAC,
} TCMD_CONT_RX_ACT;

typedef PREPACK struct {
	uint32_t testCmdId;
	uint32_t act;
	uint32_t enANI;
	PREPACK union {
		struct PREPACK TCMD_CONT_RX_PARA {
			uint32_t freq;
			uint32_t antenna;
			uint32_t wlanMode;
		} POSTPACK para;
		struct PREPACK TCMD_CONT_RX_REPORT {
			uint32_t totalPkt;
			int32_t rssiInDBm;
			uint32_t crcErrPkt;
			uint32_t secErrPkt;
			uint16_t rateCnt[TCMD_MAX_RATES];
			uint16_t rateCntShortGuard[TCMD_MAX_RATES];
		} POSTPACK report;
		struct PREPACK TCMD_CONT_RX_MAC {
			char addr[ATH_MAC_LEN];
			char btaddr[ATH_MAC_LEN];
                        uint16_t regDmn[2];
                        uint32_t otpWriteFlag;
		} POSTPACK mac;
		struct PREPACK TCMD_CONT_RX_ANT_SWITCH_TABLE {
			uint32_t antswitch1;
			uint32_t antswitch2;
		} POSTPACK antswitchtable;
	} POSTPACK u;
} POSTPACK TCMD_CONT_RX;

/* Force sleep/wake  test cmd
 mode: TCMD_PM_WAKEUP - Wakeup the target
       TCMD_PM_SLEEP - Force the target to sleep.
 */
typedef enum {
	TCMD_PM_WAKEUP = 1,	/* be consistent with target */
	TCMD_PM_SLEEP,
	TCMD_PM_DEEPSLEEP
} TCMD_PM_MODE;

typedef enum {
    TC_CMDS_VERSION_RESERVED=0,
    TC_CMDS_VERSION_MDK,
    TC_CMDS_VERSION_TS,
    TC_CMDS_VERSION_LAST,
} TC_CMDS_VERSION;

typedef enum {
    TC_CMDS_TS =0,
    TC_CMDS_CAL,
    TC_CMDS_TPCCAL = TC_CMDS_CAL,
    TC_CMDS_TPCCAL_WITH_OTPWRITE,
    TC_CMDS_OTPDUMP,
    TC_CMDS_OTPSTREAMWRITE,
    TC_CMDS_EFUSEDUMP,
    TC_CMDS_EFUSEWRITE,
    TC_CMDS_READTHERMAL,
    TC_CMDS_PM_CAL,
    TC_CMDS_PSAT_CAL,
    TC_CMDS_PSAT_CAL_RESULT,
    TC_CMDS_CAL_PWRS,
    TC_CMDS_WRITE_CAL_2_OTP,
    TC_CMDS_CHAR_PSAT,
    TC_CMDS_CHAR_PSAT_RESULT,
    TC_CMDS_PM_CAL_RESULT,
    TC_CMDS_SINIT_WAIT,
    TC_CMDS_COUNT
} TC_CMDS_ACT;

typedef PREPACK struct {
    uint32_t   testCmdId;
    uint32_t   act;
    PREPACK union {
        uint32_t  enANI;    // to be identical to CONT_RX struct
        struct PREPACK {
            uint16_t   length;
            uint8_t    version;
            uint8_t    bufLen;
        } POSTPACK parm;
    } POSTPACK u;
} POSTPACK TC_CMDS_HDR;

typedef PREPACK struct {
    TC_CMDS_HDR  hdr;
    char buf[TC_CMDS_SIZE_MAX];
} POSTPACK TC_CMDS;

typedef PREPACK struct {
    uint32_t    testCmdId;
    uint32_t    regAddr;
    uint32_t    val;
    uint16_t    flag;
} POSTPACK TCMD_SET_REG;

typedef PREPACK struct {
	uint32_t testCmdId;
	uint32_t mode;
} POSTPACK TCMD_PM;

typedef enum {
	TCMD_CONT_TX_ID,
	TCMD_CONT_RX_ID,
	TCMD_PM_ID,
        TC_CMDS_ID,
        TCMD_SET_REG_ID,

	/*For synergy purpose we added the following tcmd id but these
	tcmd's will not go to the firmware instead we will write values
	to the NV area */

	TCMD_NIC_MAC = 100,
	TCMD_CAL_FILE_INDEX = 101,
} TCMD_ID;

typedef PREPACK struct
{
    uint32_t  testCmdId;
    char   mac_address[ATH_MAC_LEN];
} POSTPACK TCMD_NIC_MAC_S;

typedef PREPACK struct
{
       uint32_t  testCmdId;
       uint32_t  cal_file_index;
} POSTPACK TCMD_CAL_FILE_INDEX_S;

typedef PREPACK union {
	TCMD_CONT_TX contTx;
	TCMD_CONT_RX contRx;
	TCMD_PM pm;
          // New test cmds from ART/MDK ...
        TC_CMDS              tcCmds;
        TCMD_SET_REG setReg;
} POSTPACK TEST_CMD;

/* New structure for selfinit */
typedef enum {
    TC_MSG_RESERVED,
    TC_MSG_PSAT_CAL_RESULTS,
    TC_MSG_CAL_POWER,
    TC_MSG_CHAR_PSAT_RESULTS,
    TC_MSG_PM_CAL_RESULTS,
    TC_MSG_PSAT_CAL_ACK,
    TC_MSG_COUNT
} TC_MSG_ID;

typedef PREPACK struct {
    int8_t  olpcGainDelta_diff;
    int8_t  olpcGainDelta_abs;
    uint8_t thermCalVal;
    uint8_t numTryBF;
    uint32_t  cmac_olpc;
    uint32_t  cmac_psat;
    uint16_t  cmac_olpc_pcdac;
    uint16_t  cmac_psat_pcdac;
    int16_t   lineSlope;
    int16_t   lineVariance;
    uint16_t  psatParm;
    uint8_t reserved[2];
} POSTPACK OLPCGAIN_THERM_DUPLET;

#define WHAL_NUM_11G_CAL_PIERS_EXT 16
#define WHAL_NUM_11A_CAL_PIERS_EXT 32
#define PSAT_WHAL_NUM_11G_CAL_PIERS_MAX 3
#define PSAT_WHAL_NUM_11A_CAL_PIERS_MAX 5
#define NUM_PSAT_CHAR_PARMS  7
#define _MAX_TX_GAIN_ENTRIES 32

typedef PREPACK struct {
    OLPCGAIN_THERM_DUPLET olpcGainTherm2G[PSAT_WHAL_NUM_11G_CAL_PIERS_MAX];
    OLPCGAIN_THERM_DUPLET olpcGainTherm5G[PSAT_WHAL_NUM_11A_CAL_PIERS_MAX];
} POSTPACK PSAT_CAL_RESULTS;

typedef PREPACK struct {
    uint32_t  cmac_i[_MAX_TX_GAIN_ENTRIES];
    uint8_t pcdac[_MAX_TX_GAIN_ENTRIES];

    uint8_t freq;
    uint8_t an_txrf3_rdiv2g;
    uint8_t an_txrf3_pdpredist2g;
    uint8_t an_rxtx2_mxrgain;
    uint8_t an_rxrf_bias1_pwd_ic25mxr2gh;
    uint8_t an_bias2_pwd_ic25rxrf;
    uint8_t an_bb1_i2v_curr2x;
    uint8_t an_txrf3_capdiv2g;

} POSTPACK CHAR_PSAT_RESULTS;

typedef PREPACK struct {
    int16_t txPwr2G_t10[WHAL_NUM_11G_CAL_PIERS_EXT];
    int16_t txPwr5G_t10[WHAL_NUM_11A_CAL_PIERS_EXT];
} POSTPACK CAL_TXPWR;

typedef PREPACK struct {
    uint8_t thermCalVal;
    uint8_t future[3];
} POSTPACK PM_CAL_RESULTS;

typedef PREPACK struct {
    TC_MSG_ID msgId;
    PREPACK union {
        PSAT_CAL_RESULTS  psatCalResults;
        CAL_TXPWR txPwrs;
        CHAR_PSAT_RESULTS psatCharResults;
        PM_CAL_RESULTS  pmCalResults;
    } POSTPACK msg;

} POSTPACK TC_MSG;

typedef struct _psat_sweep_table {
    uint8_t  an_txrf3_rdiv2g;
    uint8_t  an_txrf3_pdpredist2g;
    uint8_t  an_rxtx2_mxrgain;
    uint8_t  an_rxrf_bias1_pwd_ic25mxr2gh;
    uint8_t  an_bias2_pwd_ic25rxrf;
    uint8_t  an_bb1_i2v_curr2x;
    uint8_t  an_txrf3_capdiv2g;
    int8_t   olpcPsatCmacDelta;
    uint16_t psatParm;
    uint16_t padding2;
} PSAT_SWEEP_TABLE;

#ifdef __cplusplus
}
#endif

#endif /* TESTCMD_H_ */
