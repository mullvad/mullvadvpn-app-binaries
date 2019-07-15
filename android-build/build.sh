#!/usr/bin/env bash

set -e

for arch_info in "arm64|aarch64" "x86_64|x86_64"; do
    export ANDROID_ARCH_NAME="$(echo "$arch_info" | cut -f1 -d'|')"
    export ANDROID_LLVM_ARCH="$(echo "$arch_info" | cut -f2 -d'|')"
    export ANDROID_LLVM_TRIPLE="${ANDROID_LLVM_ARCH}-linux-android"
    export ANDROID_TOOLCHAIN_ROOT="/opt/android/toolchains/android21-${ANDROID_LLVM_ARCH}"
    export ANDROID_SYSROOT="${ANDROID_TOOLCHAIN_ROOT}/sysroot"
    export ANDROID_C_COMPILER="${ANDROID_TOOLCHAIN_ROOT}/bin/${ANDROID_LLVM_TRIPLE}21-clang"

    # Build OpenSSL
    export OPENSSL_CONFIG="no-weak-ssl-ciphers no-ssl3 no-ssl3-method no-bf no-rc2 no-rc4 no-rc5 no-md4 no-seed no-cast no-camellia no-idea enable-ec_nistp_64_gcc_128 enable-rfc3779"
    export PATH="$PATH:${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin"

    pushd openssl
    ./Configure "android-$ANDROID_ARCH_NAME" -D__ANDROID_API__=21 no-shared -static --prefix=/opt/openssl --openssldir=/opt/openssl ${OPENSSL_CONFIG}
    make clean
    make build_libs

    mkdir -p "../${ANDROID_LLVM_TRIPLE}/include/openssl"
    cp lib{crypto,ssl}.a "../${ANDROID_LLVM_TRIPLE}/"
    cp include/openssl/openssl{conf,v}.h "../${ANDROID_LLVM_TRIPLE}/include/openssl/"
    popd

    # Build Wireguard-Go
    pushd wireguard-go/
    make -f Android.mk clean

    export CFLAGS="-D__ANDROID_API__=21"
    export LDFLAGS="-L${ANDROID_SYSROOT}/usr/lib/${ANDROID_LLVM_TRIPLE}/21"

    make -f Android.mk
    popd
done
