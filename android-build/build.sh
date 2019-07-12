#!/usr/bin/env bash

set -e

# Build OpenSSL
export OPENSSL_CONFIG="no-weak-ssl-ciphers no-ssl3 no-ssl3-method no-bf no-rc2 no-rc4 no-rc5 no-md4 no-seed no-cast no-camellia no-idea enable-ec_nistp_64_gcc_128 enable-rfc3779"
export PATH="$PATH:$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin"

pushd openssl
./Configure android-arm64 -D__ANDROID_API__=21 no-shared -static --prefix=/opt/openssl --openssldir=/opt/openssl ${OPENSSL_CONFIG}
make clean
make build_libs

mkdir -p ../aarch64-linux-android/include/openssl
cp lib{crypto,ssl}.a ../aarch64-linux-android/
cp include/openssl/openssl{conf,v}.h ../aarch64-linux-android/include/openssl/
popd

# Build Wireguard-Go
pushd wireguard-go/
make -f Android.mk clean

export CFLAGS="-D__ANDROID_API__=21"
export LDFLAGS="-L${ANDROID_SYSROOT}/usr/lib/aarch64-linux-android/21"

make -f Android.mk
popd
