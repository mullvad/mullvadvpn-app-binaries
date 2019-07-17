#!/usr/bin/env bash

set -e

for arch in arm arm64 x86_64 x86; do
    case "$arch" in
        "arm64")
            export ANDROID_LLVM_TRIPLE="aarch64-linux-android"
            export ANDROID_LIB_TRIPLE="aarch64-linux-android"
            export RUST_TARGET_TRIPLE="aarch64-linux-android"
            export RUST_LLVM_ARCH="aarch64"
            ;;
        "x86_64")
            export ANDROID_LLVM_TRIPLE="x86_64-linux-android"
            export ANDROID_LIB_TRIPLE="x86_64-linux-android"
            export RUST_TARGET_TRIPLE="x86_64-linux-android"
            export RUST_LLVM_ARCH="x86_64"
            ;;
        "arm")
            export ANDROID_LLVM_TRIPLE="armv7a-linux-androideabi"
            export ANDROID_LIB_TRIPLE="arm-linux-androideabi"
            export RUST_TARGET_TRIPLE="armv7-linux-androideabi"
            export RUST_LLVM_ARCH="armv7"
            ;;
        "x86")
            export ANDROID_LLVM_TRIPLE="i686-linux-android"
            export ANDROID_LIB_TRIPLE="i686-linux-android"
            export RUST_TARGET_TRIPLE="i686-linux-android"
            export RUST_LLVM_ARCH="i686"
            ;;
    esac

    export ANDROID_ARCH_NAME="$arch"
    export ANDROID_TOOLCHAIN_ROOT="/opt/android/toolchains/android21-${RUST_LLVM_ARCH}"
    export ANDROID_SYSROOT="${ANDROID_TOOLCHAIN_ROOT}/sysroot"
    export ANDROID_C_COMPILER="${ANDROID_TOOLCHAIN_ROOT}/bin/${ANDROID_LLVM_TRIPLE}21-clang"

    # Build OpenSSL
    export PATH="$PATH:${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin"

    OPENSSL_CONFIG="no-weak-ssl-ciphers no-ssl3 no-ssl3-method no-bf no-rc2 no-rc4 no-rc5 no-md4 no-seed no-cast no-camellia no-idea enable-rfc3779"
    if echo "$ANDROID_ARCH_NAME" | grep -q 64; then
        OPENSSL_CONFIG+=" enable-ec_nistp_64_gcc_128"
    fi

    pushd openssl
    ./Configure "android-$ANDROID_ARCH_NAME" -D__ANDROID_API__=21 no-shared -static --prefix=/opt/openssl --openssldir=/opt/openssl ${OPENSSL_CONFIG}
    make clean
    make build_libs

    mkdir -p "../${RUST_TARGET_TRIPLE}/include/openssl"
    cp lib{crypto,ssl}.a "../${RUST_TARGET_TRIPLE}/"
    cp include/openssl/openssl{conf,v}.h "../${RUST_TARGET_TRIPLE}/include/openssl/"
    popd

    # Build Wireguard-Go
    pushd wireguard-go/
    make -f Android.mk clean

    export CFLAGS="-D__ANDROID_API__=21"
    export LDFLAGS="-L${ANDROID_SYSROOT}/usr/lib/${ANDROID_LIB_TRIPLE}/21"

    make -f Android.mk
    popd
done
