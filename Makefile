ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:latest
INSTALL_TARGET_PROCESSES = YourApp

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TokenTweak

TokenTweak_FILES = Tweak.m
TokenTweak_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
