TARGET = iphone:clang:latest:5.0
PACKAGE_VERSION = 0.0.2

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = JSFS
JSFS_FILES = Switch.xm
JSFS_LIBRARIES = flipswitch
JSFS_INSTALL_PATH = /Library/Switches

include $(THEOS_MAKE_PATH)/bundle.mk
