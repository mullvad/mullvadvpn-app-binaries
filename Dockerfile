# To build the image:
# podman build . -t mullvadvpn-app-binaries
#
# Example using the makefile to cross-compile openvpn for windows:
# podman run --rm -v .:/build:Z mullvadvpn-app-binaries /bin/sh -c 'make openvpn_windows'

# Debian 10 is the oldest supported distro. It has the oldest glibc that we support
# This checksum points to a 10.13-slim image.
FROM debian@sha256:557ee531b81ce380d012d83b7bb56211572e5d6088d3e21a3caef7d7ed7f718b

RUN apt-get update -y && apt-get install -y \
    git curl wget unzip bzip2 \
    pkg-config make autoconf libtool \
    gcc iproute2 \
    gcc-aarch64-linux-gnu \
    gcc-mingw-w64 mingw-w64-common \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
