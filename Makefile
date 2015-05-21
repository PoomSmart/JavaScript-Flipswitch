TARGET = iphone:latest:5.0
ARCHS = armv7 arm64

include theos/makefiles/common.mk

BUNDLE_NAME = JSFS
JSFS_FILES = Switch.xm
JSFS_LIBRARIES = flipswitch substrate
JSFS_INSTALL_PATH = /Library/Switches

include $(THEOS_MAKE_PATH)/bundle.mk