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

#ifndef  _PSAT_COMMON_H_
#define  _PSAT_COMMON_H_

#include <stdint.h>
#include "testcmd.h"

#define DEVIDE_COEFF 10000

// CMAC to power lookup table, for platform such as embedded without sophisticated math function 
typedef struct {
    uint32_t cmac;
    int32_t  pwr_t10;
} _CMAP_PWR_MAPPING;

extern _CMAP_PWR_MAPPING CmacPwrLkupTbl[];
#define CMAC_PWR_LOOKUP_MAX (sizeof(CmacPwrLkupTbl) / sizeof(_CMAP_PWR_MAPPING))

extern PSAT_SWEEP_TABLE psatSweepTbl[];
extern uint16_t NumEntriesPSTSweepTable;

int32_t interpolate_round(int32_t target, int32_t srcLeft, int32_t srcRight,
            int32_t targetLeft, int32_t targetRight, int32_t roundUp);
int16_t cmac2Pwr_t10(uint32_t cmac);

#endif //#ifndef _PSAT_COMMON_H_
