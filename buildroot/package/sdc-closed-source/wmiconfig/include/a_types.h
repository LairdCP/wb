//------------------------------------------------------------------------------
// <copyright file="a_types.h" company="Atheros">
//    Copyright (c) 2004-2010 Atheros Corporation.  All rights reserved.
// $ATH_LICENSE_HOSTSDK0_C$
//------------------------------------------------------------------------------
//==============================================================================
// This file contains the definitions of the basic atheros data types.
// It is used to map the data types in atheros files to a platform specific
// type.
//
// Author(s): ="Atheros"
//==============================================================================
#ifndef _A_TYPES_H_
#define _A_TYPES_H_

#if defined(__linux__) && !defined(LINUX_EMULATION)
#include "athtypes_linux.h"
#endif

#ifdef ATHR_WM_NWF
#include "../os/windows/include/athtypes.h"
#endif

#ifdef ATHR_CE_LEGACY
#include "../os/windows/include/athtypes.h"
#endif

#ifdef REXOS
#include "../os/rexos/include/common/athtypes_rexos.h"
#endif

#if defined ART_WIN
#include "../os/win_art/include/athtypes_win.h"
#endif

#ifdef ATHR_WIN_NWF
#include <athtypes_win.h>
#endif

#endif /* _ATHTYPES_H_ */

