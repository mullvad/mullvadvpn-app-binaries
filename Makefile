
BUILD_DIR = $(PWD)/build

STRIP = strip

OPENSSL_CONFIGURE_SCRIPT = ./config
OPENSSL_VERSION = 1.1.1t
OPENSSL_CONFIG = no-weak-ssl-ciphers no-ssl3 no-ssl3-method no-bf no-rc2 no-rc4 no-rc5 \
	no-md4 no-seed no-cast no-camellia no-idea enable-ec_nistp_64_gcc_128 enable-rfc3779
# To stop OpenSSL from loading C:\etc\ssl\openvpn.cnf (and equivalent) on start.
# Prevents escalation attack to SYSTEM user.
OPENSSL_CONFIG += no-autoload-config

OPENSSL_LIBS = -L$(BUILD_DIR)/lib -lssl -lcrypto -lpthread -ldl

OPENVPN_VERSION = 2.6.0
OPENVPN_CONFIG = --enable-static --disable-shared --disable-debug --disable-plugin-down-root \
	--disable-management --disable-port-share --disable-systemd --disable-dependency-tracking \
	--disable-pkcs11 --disable-plugin-auth-pam --enable-plugins \
	--disable-lzo --disable-lz4 --enable-comp-stub

LIBMNL_CONFIG = --enable-static --disable-shared
LIBNFTNL_CONFIG = --enable-static --disable-shared

LIBNFTNL_CFLAGS = -g -O2

# You likely need GNU Make for this to work.
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

ifeq ($(UNAME_S),Linux)
	HOST = "$(UNAME_M)-unknown-linux-gnu"
endif
ifeq ($(UNAME_S),Darwin)
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
	PLATFORM_OPENVPN_CONFIG = --host=aarch64-apple-darwin
endif

ifneq (,$(findstring unknown-linux-gnu,$(TARGET)))
	PLATFORM_OPENSSL_CONFIG = -static
	PLATFORM_OPENVPN_CONFIG = --enable-dco --disable-iproute2
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

ifeq ($(TARGET),x86_64-pc-windows-msvc)
	OPENSSL_CONFIGURE_SCRIPT = ./Configure
	CTARGET = x86_64-w64-mingw32
	PLATFORM_OPENSSL_CONFIG += -static-libgcc no-capieng
	PLATFORM_OPENSSL_CONFIG += --cross-compile-prefix=$(CTARGET)- mingw64

	OPENSSL_LIBS = -L$(BUILD_DIR)/lib -lssl -lcrypto -lws2_32 -lgdi32

	PLATFORM_OPENVPN_CONFIG += --host=x86_64-w64-mingw32
	PLATFORM_OPENVPN_CONFIG += --build=x86_64-pc-linux-gnu

	export LDFLAGS := -Wl,-Bstatic
	OPENVPN_CFLAGS = -O2 -flto

	BIN_EXT = .exe
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
		CFLAGS="$(OPENVPN_CFLAGS)" \
		LIBNL_GENL_CFLAGS="-I$(PWD)/libnl/include" \
		LIBNL_GENL_LIBS="-L$(PWD)/libnl/lib/.libs -lnl-genl-3" \
		TAP_CFLAGS="-I$(PWD)/x86_64-pc-windows-msvc/tap-windows" \
		OPENSSL_CFLAGS="-I$(BUILD_DIR)/include" \
		OPENSSL_LIBS="$(OPENSSL_LIBS)" ; \
	$(MAKE) clean ; \
	$(MAKE) ; \
	$(MAKE) install
	$(STRIP) $(BUILD_DIR)/sbin/openvpn
	cp $(BUILD_DIR)/sbin/openvpn$(BIN_EXT) $(TARGET)/

ifneq (,$(findstring unknown-linux-gnu,$(TARGET)))

libnl:
	@echo "Building libnl"
	cd libnl; \
	./autogen.sh; \
	./configure --enable-static --disable-shared --enable-cli=no --disable-debug; \
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
