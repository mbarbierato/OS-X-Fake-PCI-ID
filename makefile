KEXT=FakePCIID.kext
#KEXT_WIFI=FakePCIID_AR9280_as_AR946x.kext
KEXT_WIFI=FakePCIID_Broadcom_WiFi.kext
KEXT_GFX=FakePCIID_Intel_HD_Graphics.kext
KEXT_USB=FakePCIID_XHCIMux.kext
DIST=RehabMan-FakePCIID
BUILDDIR=./Build

VERSION_ERA=$(shell ./print_version.sh)
ifeq "$(VERSION_ERA)" "10.10-"
	INSTDIR=/System/Library/Extensions
else
	INSTDIR=/Library/Extensions
endif

ifeq ($(findstring 32,$(BITS)),32)
OPTIONS:=$(OPTIONS) -arch i386
endif

ifeq ($(findstring 64,$(BITS)),64)
OPTIONS:=$(OPTIONS) -arch x86_64
endif

OPTIONS:=$(OPTIONS) -scheme FakePCIID

.PHONY: all
all:
	xcodebuild build $(OPTIONS) -configuration Debug
	xcodebuild build $(OPTIONS) -configuration Release

.PHONY: clean
clean:
	xcodebuild clean $(OPTIONS) -configuration Debug
	xcodebuild clean $(OPTIONS) -configuration Release

.PHONY: update_kernelcache
update_kernelcache:
	sudo touch /System/Library/Extensions
	sudo kextcache -update-volume /

.PHONY: install_debug
install_debug:
	sudo rm -Rf $(INSTDIR)/$(KEXT)
	sudo cp -R $(BUILDDIR)/Debug/$(KEXT) $(INSTDIR)
	sudo rm -Rf $(INSTDIR)/$(KEXT_GFX)
	sudo cp -R $(BUILDDIR)/Debug/$(KEXT_GFX) $(INSTDIR)
	sudo rm -Rf $(INSTDIR)/$(KEXT_WIFI)
	sudo cp -R $(BUILDDIR)/Debug/$(KEXT_WIFI) $(INSTDIR)
	if [ "`which tag`" != "" ]; then sudo tag -a Purple $(INSTDIR)/$(KEXT); fi
	if [ "`which tag`" != "" ]; then sudo tag -a Purple $(INSTDIR)/$(KEXT_GFX); fi
	if [ "`which tag`" != "" ]; then sudo tag -a Purple $(INSTDIR)/$(KEXT_WIFI); fi
	make update_kernelcache

.PHONY: install
install:
	sudo rm -Rf $(INSTDIR)/$(KEXT)
	sudo cp -R $(BUILDDIR)/Release/$(KEXT) $(INSTDIR)
	sudo rm -Rf $(INSTDIR)/$(KEXT_GFX)
	sudo cp -R $(BUILDDIR)/Release/$(KEXT_GFX) $(INSTDIR)
	sudo rm -Rf $(INSTDIR)/$(KEXT_WIFI)
	sudo cp -R $(BUILDDIR)/Release/$(KEXT_WIFI) $(INSTDIR)
	if [ "`which tag`" != "" ]; then sudo tag -a Blue $(INSTDIR)/$(KEXT); fi
	if [ "`which tag`" != "" ]; then sudo tag -a Blue $(INSTDIR)/$(KEXT_GFX); fi
	if [ "`which tag`" != "" ]; then sudo tag -a Blue $(INSTDIR)/$(KEXT_WIFI); fi
	make update_kernelcache

.PHONY: install_debug_usb
install_debug_usb:
	sudo rm -Rf $(INSTDIR)/$(KEXT_USB)
	sudo cp -R $(BUILDDIR)/Debug/$(KEXT_USB) $(INSTDIR)
	if [ "`which tag`" != "" ]; then sudo tag -a Purple $(INSTDIR)/$(KEXT_USB); fi
	make install_debug

.PHONY: install_usb
install_usb:
	sudo rm -Rf $(INSTDIR)/$(KEXT_USB)
	sudo cp -R $(BUILDDIR)/Release/$(KEXT_USB) $(INSTDIR)
	if [ "`which tag`" != "" ]; then sudo tag -a Blue $(INSTDIR)/$(KEXT_USB); fi
	make install

.PHONY: distribute
distribute:
	if [ -e ./Distribute ]; then rm -r ./Distribute; fi
	mkdir ./Distribute
	cp README.md ./Distribute
	cp -R $(BUILDDIR)/Debug ./Distribute
	cp -R $(BUILDDIR)/Release ./Distribute
	mkdir ./Distribute/injectors
	cp -R AppleIntelKBLGraphicsFramebufferInjector_3e9x.kext ./Distribute/injectors
	cp -R BroadcomWiFiInjector.kext ./Distribute/injectors
	find ./Distribute -path *.DS_Store -delete
	find ./Distribute -path *.dSYM -exec echo rm -r {} \; >/tmp/org.voodoo.rm.dsym.sh
	chmod +x /tmp/org.voodoo.rm.dsym.sh
	/tmp/org.voodoo.rm.dsym.sh
	rm /tmp/org.voodoo.rm.dsym.sh
	ditto -c -k --sequesterRsrc --zlibCompressionLevel 9 ./Distribute ./Archive.zip
	mv ./Archive.zip ./Distribute/`date +$(DIST)-%Y-%m%d.zip`
