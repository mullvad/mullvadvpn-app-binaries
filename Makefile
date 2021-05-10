
BUILD_DIR = $(PWD)/build
WINDOWS_BUILDROOT = openvpn-build/generic/tmp
WINDOWS_SOURCEROOT = openvpn-build/generic/sources

OPENSSL_CONFIGURE_SCRIPT = ./config
OPENSSL_VERSION = openssl-1.1.1j
OPENSSL_CONFIG = no-weak-ssl-ciphers no-ssl3 no-ssl3-method no-bf no-rc2 no-rc4 no-rc5 \
	no-md4 no-seed no-cast no-camellia no-idea enable-ec_nistp_64_gcc_128 enable-rfc3779
# To stop OpenSSL from loading C:\etc\ssl\openvpn.cnf (and equivalent) on start.
# Prevents escalation attack to SYSTEM user.
OPENSSL_CONFIG += no-autoload-config

OPENVPN_VERSION = openvpn-2.5.1
OPENVPN_CONFIG = --enable-static --disable-shared --disable-debug --disable-server \
	--disable-management --disable-port-share --disable-systemd --disable-dependency-tracking \
	--disable-def-auth --disable-pf --disable-pkcs11 --disable-lzo --disable-plugin-auth-pam \
	--enable-lz4 --enable-crypto --enable-plugins

# You likely need GNU Make for this to work.
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)
LIBNFTNL_CFLAGS = "-g -O2 -mcmodel=large"
ifeq ($(UNAME_S),Linux)
	PLATFORM_OPENSSL_CONFIG = -static
	PLATFORM_OPENVPN_CONFIG = --enable-iproute2
	SHARED_LIB_EXT = so*
	TARGET_TRIPLE = "$(UNAME_M)-unknown-linux-gnu"
	# ARM doesn't support 'mcmodel=large'
	ifeq ($(UNAME_M),aarch64)
		LIBNFTNL_CFLAGS = "-g -O2"
	else ifneq (,$(findstring arm,$(UNAME_M)))
		LIBNFTNL_CFLAGS = "-g -O2"
	endif
endif
ifeq ($(UNAME_S),Darwin)
	SHARED_LIB_EXT = dylib
	MACOSX_DEPLOYMENT_TARGET = "10.13"
	TARGET_TRIPLE = "x86_64-apple-darwin"
endif
ifneq (,$(findstring MINGW,$(UNAME_S)))
	TARGET_TRIPLE = "x86_64-pc-windows-msvc"
endif

ifeq ($(TARGET),)
	RUST_RELEASE_DIR = "target/release"
else
	TARGET_TRIPLE = $(TARGET)
	RUST_RELEASE_DIR = "target/$(TARGET)/release"
endif

ifeq ($(TARGET),aarch64-apple-darwin)
	MACOSX_DEPLOYMENT_TARGET = "11.0"
	OPENSSL_CONFIGURE_SCRIPT = ./Configure
	PLATFORM_OPENSSL_CONFIG += darwin64-arm64-cc
	CFLAGS = -arch arm64 -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)
	LDFLAGS = -arch arm64 -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)
	PLATFORM_OPENVPN_CONFIG = --target=aarch64-apple-darwin --host=aarch64-apple-darwin
	LIBSODIUM_OPTIONS = --host=aarch64-apple-darwin
	SHADOWSOCKS_CARGO_OPTIONS = --target=aarch64-apple-darwin
endif

.PHONY: help clean clean-build clean-submodules lz4 openssl openvpn openvpn_windows libmnl libnftnl libsodium shadowsocks_linux shadowsocks_macos

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
	mkdir -p $(BUILD_DIR) $(TARGET_TRIPLE)
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
	strip $(BUILD_DIR)/sbin/openvpn
	cp $(BUILD_DIR)/sbin/openvpn $(TARGET_TRIPLE)/

openvpn_windows: clean-submodules
	rm -r "$(WINDOWS_BUILDROOT)"
	mkdir -p $(WINDOWS_BUILDROOT)
	mkdir -p $(WINDOWS_SOURCEROOT)
	ln -sf $(PWD)/openssl $(WINDOWS_BUILDROOT)/$(OPENSSL_VERSION)
	ln -sf $(PWD)/openvpn $(WINDOWS_BUILDROOT)/$(OPENVPN_VERSION)
	cd openvpn; autoreconf -f -v
	EXTRA_OPENVPN_CONFIG="$(OPENVPN_CONFIG)" \
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
	cd libmnl; \
	./autogen.sh; \
	./configure --enable-static --disable-shared; \
	$(MAKE) clean; \
	$(MAKE)
	cp libmnl/src/.libs/libmnl.a $(TARGET_TRIPLE)/

libnftnl: libmnl
	@echo "Building libnftnl"
	cd libnftnl; \
	./autogen.sh; \
	LIBMNL_LIBS="-L$(PWD)/libmnl/src/.libs -lmnl" \
		LIBMNL_CFLAGS="-I$(PWD)/libmnl/include" \
		CFLAGS=$(LIBNFTNL_CFLAGS) \
		./configure --enable-static --disable-shared; \
	$(MAKE) clean; \
	$(MAKE)
	cp libnftnl/src/.libs/libnftnl.a $(TARGET_TRIPLE)/

libsodium:
	@echo "Building libsodium"
	cd libsodium; \
	export CFLAGS="$(CFLAGS)"; \
	./autogen.sh; \
	./configure --disable-shared --enable-static=yes $(LIBSODIUM_OPTIONS); \
	$(MAKE) clean; \
	$(MAKE)

shadowsocks_linux: libsodium openssl
	@echo "Building shadowsocks"
	cd shadowsocks-rust; \
	unset CARGO_TARGET_DIR; \
	SODIUM_LIB_DIR=$(PWD)/libsodium/src/libsodium/.libs/ \
		OPENSSL_STATIC=1 \
		OPENSSL_LIB_DIR=$(BUILD_DIR)/lib \
		OPENSSL_INCLUDE_DIR="$(BUILD_DIR)/include" \
		CARGO_INCREMENTAL=0 \
		cargo +stable build --no-default-features --features sodium --release --bin sslocal
	strip shadowsocks-rust/$(RUST_RELEASE_DIR)/sslocal
	cp shadowsocks-rust/$(RUST_RELEASE_DIR)/sslocal $(TARGET_TRIPLE)/

shadowsocks_macos: libsodium
	@echo "Building shadowsocks"
	mkdir -p $(TARGET_TRIPLE); \
	cd shadowsocks-rust; \
	unset CARGO_TARGET_DIR; \
	SODIUM_LIB_DIR=$(PWD)/libsodium/src/libsodium/.libs/ \
		CARGO_INCREMENTAL=0 \
		cargo +stable build $(SHADOWSOCKS_CARGO_OPTIONS) --no-default-features --features sodium \
			--release --bin sslocal
	strip shadowsocks-rust/$(RUST_RELEASE_DIR)/sslocal
	cp shadowsocks-rust/$(RUST_RELEASE_DIR)/sslocal $(TARGET_TRIPLE)/
