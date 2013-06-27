//------------------------------------------------------------------------------
// Copyright (c) 2005-2010 Atheros Corporation.  All rights reserved.
// $ATH_LICENSE_HOSTSDK0_C$
//------------------------------------------------------------------------------
//==============================================================================
// Author(s): ="Atheros"
//==============================================================================

#ifndef __PKT_LOG_H__
#define __PKT_LOG_H__

#ifdef __cplusplus
extern "C" {
#endif


/* Pkt log info */
typedef PREPACK struct pkt_log_t {
    struct info_t {
        A_UINT16    st;
        A_UINT16    end;
        A_UINT16    cur;
    }info[4096];
    A_UINT16    last_idx;
}POSTPACK PACKET_LOG;


#ifdef __cplusplus
}
#endif
#endif  /* __PKT_LOG_H__ */
