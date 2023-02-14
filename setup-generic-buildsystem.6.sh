#!/bin/sh
# Script to setup the environment for openvpn-build/generic

BUILD_DEPS="mingw-w64 man2html dos2unix nsis unzip wget curl autoconf libtool gcc-arm-linux-gnueabi"
MINGW_PACKAGES="mingw-w64 mingw-w64-common mingw-w64-i686-dev mingw-w64-x86-64-dev"

check_if_root() {
    if ! [ `whoami` = "root" ]; then
            echo "ERROR: you must run this script as root!"
            exit 1
    fi
}

install_packages() {
    apt-get update
    apt-get -y install $BUILD_DEPS git $GNUEABI_PKG $MINGW_PACKAGES
}

# Main script
check_if_root
install_packages
