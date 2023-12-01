
BUILD_DIR = $(PWD)/build
WINDOWS_BUILDROOT = openvpn-build/generic/tmp
WINDOWS_SOURCEROOT = openvpn-build/generic/sources

STRIP = strip

OPENSSL_CONFIGURE_SCRIPT = ./config
OPENSSL_VERSION = 3.0.8
OPENSSL_CONFIG = no-weak-ssl-ciphers no-ssl3 no-ssl3-method no-bf no-rc2 no-rc4 no-rc5 \
	no-md4 no-seed no-cast no-camellia no-idea enable-ec_nistp_64_gcc_128 enable-rfc3779
# To stop OpenSSL from loading C:\etc\ssl\openvpn.cnf (and equivalent) on start.
# Prevents escalation attack to SYSTEM user.
OPENSSL_CONFIG += no-autoload-config
OPENSSL_LIB_DIR = $(BUILD_DIR)/lib64

OPENVPN_VERSION = 2.6.8
OPENVPN_CONFIG = --enable-static --disable-shared --disable-debug --disable-plugin-down-root \
	--disable-management --disable-port-share --disable-systemd --disable-dependency-tracking \
	--disable-pkcs11 --disable-plugin-auth-pam --enable-plugins \
	--disable-lzo --disable-lz4 --enable-comp-stub

LIBMNL_CONFIG = --enable-static --disable-shared
LIBNFTNL_CONFIG = --enable-static --disable-shared

LIBNL_CONFIG = --enable-static --disable-shared --enable-cli=no --disable-debug

LIBNFTNL_CFLAGS = -g -O2

# You likely need GNU Make for this to work.
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

# Compute host platform
ifeq ($(UNAME_S),Linux)
	HOST = "$(UNAME_M)-unknown-linux-gnu"
endif
ifeq ($(UNAME_S),Darwin)
	ifeq ($(UNAME_M), arm64)
		HOST = "aarch64-apple-darwin"
	else
		HOST = "$(UNAME_M)-apple-darwin"
	endif
endif
ifneq (,$(findstring MINGW,$(UNAME_S)))
	HOST = "x86_64-pc-windows-msvc"
endif

# Compute target platform
ifndef $(TARGET)
	TARGET = $(HOST)
endif

# Compute build flags for host+target combination
ifeq ($(UNAME_S),Darwin)
	OPENSSL_LIB_DIR = $(BUILD_DIR)/lib
	OPENSSL_CONFIGURE_SCRIPT = ./Configure
	PLATFORM_OPENVPN_CONFIG = --host=$(TARGET)
	ifeq ($(TARGET),x86_64-apple-darwin)
		TARGET_ARCH = "x86_64"
		MACOSX_DEPLOYMENT_TARGET = "10.13"
	endif
	ifeq ($(TARGET),aarch64-apple-darwin)
		TARGET_ARCH = "arm64"
		MACOSX_DEPLOYMENT_TARGET = "11.0"
	endif
	PLATFORM_OPENSSL_CONFIG += "darwin64-$(TARGET_ARCH)-cc"
	CFLAGS = -arch $(TARGET_ARCH) -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)
	LDFLAGS = -arch $(TARGET_ARCH) -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)
endif

ifeq ($(UNAME_S),Linux)
	PLATFORM_OPENSSL_CONFIG = -static
	PLATFORM_OPENVPN_CONFIG = --enable-dco --disable-iproute2
	ifeq ($(TARGET),aarch64-unknown-linux-gnu)
		OPENSSL_LIB_DIR = $(BUILD_DIR)/lib
		ifneq ($(HOST),aarch64-unknown-linux-gnu)
			export CC := aarch64-linux-gnu-gcc
			STRIP = aarch64-linux-gnu-strip
			OPENSSL_CONFIGURE_SCRIPT = ./Configure
			PLATFORM_OPENSSL_CONFIG += linux-aarch64
			PLATFORM_OPENVPN_CONFIG += --host=aarch64-linux
			LIBMNL_CONFIG += --host=aarch64-linux
			LIBNFTNL_CONFIG += --host=aarch64-linux
			LIBNL_CONFIG += --host=aarch64-linux
		endif
	else
		# ARM doesn't support 'mcmodel=large'
		LIBNFTNL_CFLAGS += -mcmodel=large
	endif
endif

.PHONY: help clean clean-build clean-submodules openssl openvpn openvpn_windows libmnl libnftnl libnl

help:
	@echo "Please run a more specific target"
	@echo "'make openvpn' will build a statically linked OpenVPN binary"
	@echo "'make libnftnl' will build static libraries of libmnl and libnftnl and copy to linux/"

clean: clean-build clean-submodules

clean-build:
	rm -rf $(BUILD_DIR)

clean-submodules:
	cd openssl; [ -e "Makefile" ] && $(MAKE) clean || true
	cd openvpn; [ -e "Makefile" ] && $(MAKE) clean || true

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

openvpn: openssl libnl
	@echo "Building OpenVPN"
	mkdir -p $(BUILD_DIR) $(TARGET)
	cd openvpn ; \
	export MACOSX_DEPLOYMENT_TARGET="$(MACOSX_DEPLOYMENT_TARGET)" ; \
	export CFLAGS="$(CFLAGS)"; \
	autoreconf -f -i -v ; \
	./configure \
		--prefix=$(BUILD_DIR) \
		$(OPENVPN_CONFIG) $(PLATFORM_OPENVPN_CONFIG) \
		LIBNL_GENL_CFLAGS="-I$(PWD)/libnl/include" \
		LIBNL_GENL_LIBS="-L$(PWD)/libnl/lib/.libs -lnl-genl-3" \
		OPENSSL_CFLAGS="-I$(BUILD_DIR)/include" \
		OPENSSL_LIBS="-L$(OPENSSL_LIB_DIR) -lssl -lcrypto -lpthread -ldl" ; \
	$(MAKE) clean ; \
	$(MAKE) ; \
	$(MAKE) install
	$(STRIP) $(BUILD_DIR)/sbin/openvpn
	cp $(BUILD_DIR)/sbin/openvpn $(TARGET)/

openvpn_windows: clean-submodules
	rm -rf "$(WINDOWS_BUILDROOT)"
	mkdir -p $(WINDOWS_BUILDROOT)
	mkdir -p $(WINDOWS_SOURCEROOT)
	ln -sf $(PWD)/openssl $(WINDOWS_BUILDROOT)/openssl-$(OPENSSL_VERSION)
	ln -sf $(PWD)/openvpn $(WINDOWS_BUILDROOT)/openvpn-$(OPENVPN_VERSION)
	cd openvpn; autoreconf -fiv
	EXTRA_OPENVPN_CONFIG="$(OPENVPN_CONFIG)" \
		OPENVPN_VERSION="$(OPENVPN_VERSION)" \
		OPENSSL_VERSION="$(OPENSSL_VERSION)" \
		TAP_CFLAGS="-I$(PWD)/x86_64-pc-windows-msvc/tap-windows" \
		EXTRA_OPENSSL_CONFIG="-static-libgcc no-shared $(OPENSSL_CONFIG)" \
		EXTRA_TARGET_LDFLAGS="-Wl,-Bstatic" \
		OPT_OPENVPN_CFLAGS="-O2 -flto" \
		CHOST=x86_64-w64-mingw32 \
		CBUILD=x86_64-pc-linux-gnu \
		DO_STATIC=1 \
		IMAGEROOT="$(BUILD_DIR)" \
		./openvpn-build/generic/build
	cp openvpn/src/openvpn/openvpn.exe ./x86_64-pc-windows-msvc/

ifneq (,$(findstring unknown-linux-gnu,$(TARGET)))

libnl:
	@echo "Building libnl"
	cd libnl; \
	./autogen.sh; \
	./configure $(LIBNL_CONFIG); \
	$(MAKE) clean; \
	$(MAKE)

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

else

libnl:

libmnl:

libnftnl:

endif
