#!/usr/bin/env bash

set -e

# Build OpenSSL
export OPENSSL_CONFIG="no-weak-ssl-ciphers no-ssl3 no-ssl3-method no-bf no-rc2 no-rc4 no-rc5 no-md4 no-seed no-cast no-camellia no-idea enable-ec_nistp_64_gcc_128 enable-rfc3779"
export CC="/opt/android/toolchains/android28-aarch64/bin/aarch64-linux-android28-clang"
export SYSROOT="/opt/android/toolchains/android28-aarch64/sysroot"

pushd openssl
mkdir /opt/openssl
sed -i -e 's/\([" ]\)-mandroid\([" ]\)/\1\2/g' Configurations/10-main.conf
./Configure android64-aarch64 no-shared -static --prefix=/opt/openssl --openssldir=/opt/openssl ${OPENSSL_CONFIG}
make clean
make build_libs build_apps
make install_sw
popd

mkdir -p android/include/openssl
cp /opt/openssl/lib/libcrypto.a android/libcrypto.a
cp /opt/openssl/lib/libssl.a android/libssl.a
cp /opt/openssl/include/openssl/opensslconf.h android/include/openssl/opensslconf.h
cp /opt/openssl/include/openssl/opensslv.h android/include/openssl/opensslv.h

# Build Wireguard-Go
pushd wireguard-android/app/tools/libwg-go/
sed -i -e '/export CGO_LDFLAGS/ s|$| -L/opt/android/toolchains/android28-aarch64/sysroot/usr/lib/aarch64-linux-android/28 -v|' Makefile
make
popd

cp wireguard-android/app/tools/libwg-go/out/libwg-go.h android/include/libwg-go.h
cp wireguard-android/app/tools/libwg-go/out/libwg-go.so android/libwg-go.so
