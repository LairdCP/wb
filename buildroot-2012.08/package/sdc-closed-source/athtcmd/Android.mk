#------------------------------------------------------------------------------
# <copyright file="makefile" company="Atheros">
#    Copyright (c) 2005-2010 Atheros Corporation.  All rights reserved.
# $ATH_LICENSE_HOSTSDK0_C$
#------------------------------------------------------------------------------
#==============================================================================
# Author(s): ="Atheros"
#==============================================================================

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := athtestcmd 

LOCAL_C_INCLUDES += $(TARGET_OUT_HEADERS)/libtcmd \

LOCAL_CFLAGS+=

LOCAL_SRC_FILES:= \
    athtestcmd.c  \
    sinit_common.c

LOCAL_LDLIBS += -lpthread -lrt

LOCAL_MODULE_TAGS := optional eng

LOCAL_SHARED_LIBRARIES += libcutils
LOCAL_SHARED_LIBRARIES += libnl_2
LOCAL_STATIC_LIBRARIES += libtcmd

include $(BUILD_EXECUTABLE)

include $(CLEAR_VARS)

LOCAL_MODULE := psatUtil

LOCAL_C_INCLUDES += $(TARGET_OUT_HEADERS)/libtcmd \

LOCAL_CFLAGS+=

LOCAL_SRC_FILES:= \
    psatUtil.c \
    sinit_common.c

LOCAL_LDLIBS += -lpthread -lrt

LOCAL_MODULE_TAGS := optional eng

LOCAL_SHARED_LIBRARIES += libcutils
LOCAL_SHARED_LIBRARIES += libnl_2
LOCAL_STATIC_LIBRARIES += libtcmd

include $(BUILD_EXECUTABLE)

