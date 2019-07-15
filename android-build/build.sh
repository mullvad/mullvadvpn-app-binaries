#!/usr/bin/env bash

set -e

# Build OpenSSL
export OPENSSL_CONFIG="no-weak-ssl-ciphers no-ssl3 no-ssl3-method no-bf no-rc2 no-rc4 no-rc5 no-md4 no-seed no-cast no-camellia no-idea enable-ec_nistp_64_gcc_128 enable-rfc3779"
export PATH="$PATH:$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin"

pushd openssl
./Configure android-arm64 no-shared -static --prefix=/opt/openssl --openssldir=/opt/openssl ${OPENSSL_CONFIG}
make clean
make build_libs

mkdir -p ../android/include/openssl
cp lib{crypto,ssl}.a ../android/
cp include/openssl/openssl{conf,v}.h ../android/include/openssl/
popd

# Build Wireguard-Go
pushd wireguard-go/
make -f Android.mk clean
make -f Android.mk
popd
