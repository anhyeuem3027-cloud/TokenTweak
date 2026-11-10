ARCHS = arm64
TARGET = iphone:clang:latest:16.5

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TokenTweak

TokenTweak_FILES = Tweak.m
TokenTweak_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
