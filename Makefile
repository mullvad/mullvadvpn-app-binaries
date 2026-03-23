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
	ifeq ($(UNAME_M),riscv64)
		UNAME_M = riscv64gc
	endif
	HOST = $(UNAME_M)-unknown-linux-gnu
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
	else ifeq ($(TARGET),riscv64gc-unknown-linux-gnu)
		ifneq ($(HOST),riscv64gc-unknown-linux-gnu)
			export CC := riscv64-linux-gnu-gcc
			STRIP = riscv64-linux-gnu-strip
			LIBMNL_CONFIG += --host=riscv64-linux
			LIBNFTNL_CONFIG += --host=riscv64-linux
		endif
	else
		# ARM and RISC-V don't support 'mcmodel=large'
		LIBNFTNL_CFLAGS += -mcmodel=large
	endif
endif

.PHONY: help clean clean-build libmnl libnftnl

help:
	@echo "Please run a more specific target"
	@echo "'make libnftnl' will build static libraries of libmnl and libnftnl and copy to linux/"

clean: clean-build

clean-build:
	rm -rf $(BUILD_DIR)

ifneq (,$(findstring unknown-linux-gnu,$(TARGET)))

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

libmnl:

libnftnl:

endif
