
BUILD_DIR = $(PWD)/build
WINDOWS_BUILDROOT = openvpn-build/generic/tmp
WINDOWS_SOURCEROOT = openvpn-build/generic/sources

STRIP = strip

OPENSSL_CONFIGURE_SCRIPT = ./config
OPENSSL_VERSION = 1.1.1t
OPENSSL_CONFIG = no-weak-ssl-ciphers no-ssl3 no-ssl3-method no-bf no-rc2 no-rc4 no-rc5 \
	no-md4 no-seed no-cast no-camellia no-idea enable-ec_nistp_64_gcc_128 enable-rfc3779
# To stop OpenSSL from loading C:\etc\ssl\openvpn.cnf (and equivalent) on start.
# Prevents escalation attack to SYSTEM user.
OPENSSL_CONFIG += no-autoload-config

OPENVPN_VERSION = 2.6.0
OPENVPN_CONFIG = --enable-static --disable-shared --disable-debug --disable-plugin-down-root \
	--disable-management --disable-port-share --disable-systemd --disable-dependency-tracking \
	--disable-pkcs11 --disable-lzo --disable-plugin-auth-pam --enable-lz4 --enable-plugins

LIBMNL_CONFIG = --enable-static --disable-shared
LIBNFTNL_CONFIG = --enable-static --disable-shared

LIBNFTNL_CFLAGS = -g -O2

# You likely need GNU Make for this to work.
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

ifeq ($(UNAME_S),Linux)
	PLATFORM_OPENSSL_CONFIG = -static
	PLATFORM_OPENVPN_CONFIG = --enable-iproute2
	SHARED_LIB_EXT = so*
	HOST = "$(UNAME_M)-unknown-linux-gnu"
endif
ifeq ($(UNAME_S),Darwin)
	SHARED_LIB_EXT = dylib
	MACOSX_DEPLOYMENT_TARGET = "10.13"
	HOST = "x86_64-apple-darwin"
endif
ifneq (,$(findstring MINGW,$(UNAME_S)))
	HOST = "x86_64-pc-windows-msvc"
endif

ifndef $(TARGET)
	TARGET = $(HOST)
endif

ifeq ($(TARGET),aarch64-apple-darwin)
	MACOSX_DEPLOYMENT_TARGET = "11.0"
	OPENSSL_CONFIGURE_SCRIPT = ./Configure
	PLATFORM_OPENSSL_CONFIG += darwin64-arm64-cc
	CFLAGS = -arch arm64 -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)
	LDFLAGS = -arch arm64 -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)
	PLATFORM_OPENVPN_CONFIG = --host=aarch64-apple-darwin
endif

ifeq ($(TARGET),aarch64-unknown-linux-gnu)
	ifneq ($(HOST),aarch64-unknown-linux-gnu)
		export CC := aarch64-linux-gnu-gcc
		STRIP = aarch64-linux-gnu-strip
		OPENSSL_CONFIGURE_SCRIPT = ./Configure
		PLATFORM_OPENSSL_CONFIG += linux-aarch64
		PLATFORM_OPENVPN_CONFIG += --host=aarch64-linux
		LIBMNL_CONFIG += --host=aarch64-linux
		LIBNFTNL_CONFIG += --host=aarch64-linux
	endif
else
	# ARM doesn't support 'mcmodel=large'
	LIBNFTNL_CFLAGS += -mcmodel=large
endif

.PHONY: help clean clean-build clean-submodules lz4 openssl openvpn openvpn_windows libmnl libnftnl

help:
	@echo "Please run a more specific target"
	@echo "'make openvpn' will build a statically linked OpenVPN binary"
	@echo "'make libnftnl' will build static libraries of libmnl and libnftnl and copy to linux/"

clean: clean-build clean-submodules

clean-build:
	rm -rf $(BUILD_DIR)

clean-submodules:
	cd lz4; $(MAKE) clean
	cd openssl; [ -e "Makefile" ] && $(MAKE) clean || true
	cd openvpn; [ -e "Makefile" ] && $(MAKE) clean || true

lz4:
	@echo "Building lz4"
	mkdir -p $(BUILD_DIR)
	cd lz4 ; \
	$(MAKE) clean ; \
	PREFIX=$(BUILD_DIR) LDFLAGS="$(LDFLAGS)" CFLAGS="$(CFLAGS)" $(MAKE) install LIBS="-all-static"
	# lz4 always installs a shared library. Unless it's removed
	# OpenVPN will link against it.
	rm $(BUILD_DIR)/lib/liblz4.*$(SHARED_LIB_EXT)

openssl:
	@echo "Building OpenSSL"
	mkdir -p $(BUILD_DIR)
	cd openssl; \
	export MACOSX_DEPLOYMENT_TARGET="$(MACOSX_DEPLOYMENT_TARGET)" ; \
	KERNEL_BITS=64 $(OPENSSL_CONFIGURE_SCRIPT) no-shared \
		--prefix=$(BUILD_DIR) \
		--openssldir=$(BUILD_DIR) \
		$(PLATFORM_OPENSSL_CONFIG) \
		$(OPENSSL_CONFIG) ; \
	$(MAKE) clean ; \
	$(MAKE) build_libs build_apps ; \
	$(MAKE) install_sw

openvpn: lz4 openssl
	@echo "Building OpenVPN"
	mkdir -p $(BUILD_DIR) $(TARGET)
	cd openvpn ; \
	export MACOSX_DEPLOYMENT_TARGET="$(MACOSX_DEPLOYMENT_TARGET)" ; \
	export CFLAGS="$(CFLAGS)"; \
	autoreconf -i -v ; \
	./configure \
		--prefix=$(BUILD_DIR) \
		$(OPENVPN_CONFIG) $(PLATFORM_OPENVPN_CONFIG) \
		OPENSSL_CFLAGS="-I$(BUILD_DIR)/include" \
		LZ4_CFLAGS="-I$(BUILD_DIR)/include" \
		OPENSSL_LIBS="-L$(BUILD_DIR)/lib -lssl -lcrypto -lpthread -ldl" \
		LZ4_LIBS="-L$(BUILD_DIR)/lib -llz4" ; \
	$(MAKE) clean ; \
	$(MAKE) ; \
	$(MAKE) install
	$(STRIP) $(BUILD_DIR)/sbin/openvpn
	cp $(BUILD_DIR)/sbin/openvpn $(TARGET)/

openvpn_windows: clean-submodules
	rm -rf "$(WINDOWS_BUILDROOT)"
	mkdir -p $(WINDOWS_BUILDROOT)
	mkdir -p $(WINDOWS_SOURCEROOT)
	ln -sf $(PWD)/lz4 $(WINDOWS_BUILDROOT)/lz4
	ln -sf $(PWD)/openssl $(WINDOWS_BUILDROOT)/openssl-$(OPENSSL_VERSION)
	ln -sf $(PWD)/openvpn $(WINDOWS_BUILDROOT)/openvpn-$(OPENVPN_VERSION)
	cd openvpn; autoreconf -f -v
	EXTRA_OPENVPN_CONFIG="$(OPENVPN_CONFIG)" \
		OPENVPN_VERSION="$(OPENVPN_VERSION)" \
		OPENSSL_VERSION="$(OPENSSL_VERSION)" \
		EXTRA_OPENSSL_CONFIG="-static-libgcc no-shared $(OPENSSL_CONFIG)" \
		EXTRA_TARGET_LDFLAGS="-Wl,-Bstatic" \
		OPT_OPENVPN_CFLAGS="-O2 -flto" \
		CHOST=x86_64-w64-mingw32 \
		CBUILD=x86_64-pc-linux-gnu \
		DO_STATIC=1 \
		IMAGEROOT="$(BUILD_DIR)" \
		./openvpn-build/generic/build
	cp openvpn/src/openvpn/openvpn.exe ./x86_64-pc-windows-msvc/

libmnl:
	@echo "Building libmnl"
	mkdir -p $(TARGET)
	cd libmnl; \
	./autogen.sh; \
	./configure $(LIBMNL_CONFIG); \
	$(MAKE) clean; \
	$(MAKE)
	cp libmnl/src/.libs/libmnl.a $(TARGET)/

libnftnl: libmnl
	@echo "Building libnftnl"
	mkdir -p $(TARGET)
	cd libnftnl; \
	./autogen.sh; \
	LIBMNL_LIBS="-L$(PWD)/libmnl/src/.libs -lmnl" \
		LIBMNL_CFLAGS="-I$(PWD)/libmnl/include" \
		CFLAGS="$(LIBNFTNL_CFLAGS)" \
		./configure $(LIBNFTNL_CONFIG); \
	$(MAKE) clean; \
	$(MAKE)
	cp libnftnl/src/.libs/libnftnl.a $(TARGET)/
