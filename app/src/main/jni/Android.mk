LOCAL_PATH:= $(call my-dir)

ifeq ($(TARGET_ARCH_ABI),armeabi-v7a)
PREFIX = $(PREFIX32)
endif
ifeq ($(TARGET_ARCH_ABI),arm64-v8a)
PREFIX = $(PREFIX64)
endif
ifeq ($(TARGET_ARCH_ABI),x86_64)
PREFIX = $(PREFIX_X64)
endif
ifeq ($(TARGET_ARCH_ABI),x86)
PREFIX = $(PREFIX_X86)
endif

# FongMi unified FFmpeg library. JavaVM registration is resolved from this
# library via dlsym in main.cpp so FongMi libmpv can see it.
include $(CLEAR_VARS)
LOCAL_MODULE := libffmpeg
LOCAL_SRC_FILES := $(PREFIX)/lib/libffmpeg.so
LOCAL_EXPORT_C_INCLUDES := $(PREFIX)/include
include $(PREBUILT_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := libmpv
LOCAL_SRC_FILES := $(PREFIX)/lib/libmpv.so
LOCAL_EXPORT_C_INCLUDES := $(PREFIX)/include
include $(PREBUILT_SHARED_LIBRARY)

include $(CLEAR_VARS)

LOCAL_MODULE    := libplayer
LOCAL_CFLAGS    := -Werror
LOCAL_CPPFLAGS  += -std=c++11
LOCAL_SRC_FILES := \
	main.cpp \
	render.cpp \
	log.cpp \
	jni_utils.cpp \
	property.cpp \
	event.cpp \
	node.cpp \
	thumbnail.cpp
LOCAL_LDLIBS    := -llog -lGLESv3 -lEGL -latomic
LOCAL_SHARED_LIBRARIES := ffmpeg mpv

include $(BUILD_SHARED_LIBRARY)
