BUILD_DIR = $(PWD)/build

STRIP = strip

LIBMNL_CONFIG = --enable-static --disable-shared
LIBNFTNL_CONFIG = --enable-static --disable-shared

LIBNFTNL_CFLAGS = -g -O2

# You likely need GNU Make for this to work.
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

# Compute host platform
ifeq ($(UNAME_S),Linux)
	HOST = "$(UNAME_M)-unknown-linux-gnu"
endif
ifneq (,$(findstring MINGW,$(UNAME_S)))
	HOST = "x86_64-pc-windows-msvc"
endif

# Compute target platform
ifndef $(TARGET)
	TARGET = $(HOST)
endif

# Compute build flags for host+target combination
ifeq ($(UNAME_S),Linux)
	ifeq ($(TARGET),aarch64-unknown-linux-gnu)
		ifneq ($(HOST),aarch64-unknown-linux-gnu)
			export CC := aarch64-linux-gnu-gcc
			STRIP = aarch64-linux-gnu-strip
			LIBMNL_CONFIG += --host=aarch64-linux
			LIBNFTNL_CONFIG += --host=aarch64-linux
		endif
	else ifeq ($(TARGET),x86_64-unknown-linux-musl)
		ifneq ($(HOST),x86_64-unknown-linux-musl)
			#export CC := x86_64-unknown-linux-musl
			export CC := musl-gcc -static
			LIBMNL_CONFIG += --host=x86_64-unknown-linux-musl
			LIBNFTNL_CONFIG += --host=x86_64-unknown-linux-musl
		endif
	else ifeq ($(TARGET),armv7-unknown-linux-musleabihf)
		ifneq ($(HOST),)
			export CC := arm-openwrt-linux-muslgnueabi-gcc
			LIBMNL_CONFIG += --host=armv7-unknown-linux-musleabihf
			LIBNFTNL_CONFIG += --host=armv7-unknown-linux-musleabihf
		endif
	endif
endif
# TODO: Check for target triple
# ARM doesn't support 'mcmodel=large'
# LIBNFTNL_CFLAGS += -mcmodel=large

.PHONY: help clean clean-build libmnl libnftnl

help:
	@echo "Please run a more specific target"
	@echo "'make libnftnl' will build static libraries of libmnl and libnftnl and copy to linux/"

clean: clean-build

clean-build:
	rm -rf $(BUILD_DIR)

ifneq (,$(findstring unknown-linux,$(TARGET)))

libmnl:
	@echo "Building libmnl"
	mkdir -p $(TARGET)
	cd libmnl; \
	./autogen.sh; \
	CFLAGS="$(LIBMNL_CFLAGS)" \
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

libmnl:

libnftnl:

endif
