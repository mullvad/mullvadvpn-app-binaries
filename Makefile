
BUILD_DIR = $(PWD)/build
WINDOWS_BUILDROOT = openvpn-build/generic/tmp
WINDOWS_SOURCEROOT = openvpn-build/generic/sources

OPENSSL_VERSION = openssl-1.1.0h
OPENSSL_CONFIG = no-weak-ssl-ciphers no-ssl3 no-ssl3-method no-bf no-rc2 no-rc4 no-rc5 \
	no-md4 no-seed no-cast no-camellia no-idea enable-ec_nistp_64_gcc_128 enable-rfc3779

OPENVPN_VERSION = openvpn-2.4.6
OPENVPN_CONFIG = --enable-static --disable-shared --disable-debug --disable-server \
	--disable-management --disable-port-share --disable-systemd --disable-dependency-tracking \
	--disable-def-auth --disable-pf --disable-pkcs11 \
	--enable-lzo --enable-lz4 --enable-ssl --enable-crypto --enable-plugins \
	--enable-password-save --enable-socks --enable-http-proxy

LZO_VERSION = lzo-2.10
LZO_CONFIG = --enable-static --disable-debug


# Here platforms can append specific generic make parameters if needed
MAKE_EXTRA_ARGS =

# You likely need GNU Make for this to work.
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	MAKE_EXTRA_ARGS += LIBS="-all-static"
	OPENSSL_CONFIG += -static
	SHARED_LIB_EXT = so*
endif
ifeq ($(UNAME_S),Darwin)
	SHARED_LIB_EXT = dylib
endif

.PHONY: all clean clean-build clean-submodules lz4 lzo openssl openvpn windows

all: openvpn

clean: clean-build clean-submodules

clean-build:
	rm -rf $(BUILD_DIR)

clean-submodules:
	rm -rf $(LZO_VERSION)
	cd lz4; $(MAKE) clean
	cd openssl; [ -e "Makefile" ] && $(MAKE) clean || true
	cd openvpn; [ -e "Makefile" ] && $(MAKE) clean || true

lz4:
	@echo "Building lz4"
	mkdir -p $(BUILD_DIR)
	cd lz4 ; \
	$(MAKE) clean ; \
	PREFIX=$(BUILD_DIR) $(MAKE) install $(MAKE_EXTRA_ARGS)
	# lz4 always installs a shared library. Unless it's removed
	# OpenVPN will link against it.
	rm $(BUILD_DIR)/lib/liblz4.*$(SHARED_LIB_EXT)

lzo:
	@echo "Building lzo"
	mkdir -p $(BUILD_DIR)
	rm -rf $(LZO_VERSION)
	tar xzf $(LZO_VERSION).tar.gz
	cd $(LZO_VERSION) ; \
	./configure --prefix=$(BUILD_DIR) $(LZO_CONFIG) ; \
	make ; \
	make install

openssl:
	@echo "Building OpenSSL"
	mkdir -p $(BUILD_DIR)
	cd openssl; \
	KERNEL_BITS=64 ./config no-shared \
		--prefix=$(BUILD_DIR) \
		--openssldir=$(BUILD_DIR) \
		$(OPENSSL_CONFIG) ; \
	make clean ; \
	make build_libs build_apps ; \
	make install_sw

openvpn: lz4 lzo openssl
	@echo "Building OpenVPN"
	mkdir -p $(BUILD_DIR)
	cd openvpn ; \
	autoreconf -i -v ; \
	./configure \
		--prefix=$(BUILD_DIR) \
		$(OPENVPN_CONFIG) \
		OPENSSL_CFLAGS="-I$(BUILD_DIR)/include" \
		LZO_CFLAGS="-I$(BUILD_DIR)/include" \
		LZ4_CFLAGS="-I$(BUILD_DIR)/include" \
		OPENSSL_LIBS="-L$(BUILD_DIR)/lib -lssl -lcrypto" \
		LZO_LIBS="-L$(BUILD_DIR)/lib -llzo2" \
		LZ4_LIBS="-L$(BUILD_DIR)/lib -llz4" ; \
	make clean ; \
	make $(MAKE_EXTRA_ARGS) ; \
	make install

windows: clean
	rm -rf "$(WINDOWS_BUILDROOT)"
	mkdir -p $(WINDOWS_BUILDROOT)
	mkdir -p $(WINDOWS_SOURCEROOT)
	ln -sf $(PWD)/$(LZO_VERSION).tar.gz $(WINDOWS_BUILDROOT)/../sources/$(LZO_VERSION).tar.gz
	ln -sf $(PWD)/openssl $(WINDOWS_BUILDROOT)/$(OPENSSL_VERSION)
	ln -sf $(PWD)/openvpn $(WINDOWS_BUILDROOT)/$(OPENVPN_VERSION)
	EXTRA_OPENVPN_CONFIG="$(OPENVPN_CONFIG)" \
		EXTRA_OPENSSL_CONFIG="-static-libgcc no-shared $(OPENSSL_CONFIG)" \
		CHOST=x86_64-w64-mingw32 \
		CBUILD=x86_64-pc-linux-gnu \
		DO_STATIC=1 \
		IMAGEROOT="$(BUILD_DIR)" \
		./openvpn-build/generic/build
