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

LOCAL_MODULE := wmiconfig
LOCAL_C_INCLUDES := \
	$(TARGET_OUT_HEADERS)/libtcmd \
	$(LOCAL_PATH)/include \
	$(LOCAL_PATH)/../../bionic/libc/kernel/common \
	#$(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ/usr/include \


LOCAL_CFLAGS+=-DUSER_KEYS
LOCAL_SRC_FILES:= wmiconfig.c

LOCAL_MODULE_TAGS := debug eng optional
LOCAL_SHARED_LIBRARIES += libcutils
LOCAL_SHARED_LIBRARIES += libnl_2
LOCAL_STATIC_LIBRARIES += libtcmd
include $(BUILD_EXECUTABLE)


