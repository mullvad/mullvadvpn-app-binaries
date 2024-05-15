# To build the image:
# podman build . -t mullvadvpn-app-binaries

# Debian 11 is the oldest supported distro. It has the oldest glibc that we support.
# This checksum points to a 11.6-slim image.
FROM debian@sha256:77f46c1cf862290e750e913defffb2828c889d291a93bdd10a7a0597720948fc

LABEL org.opencontainers.image.source=https://github.com/mullvad/mullvadvpn-app-binaries
LABEL org.opencontainers.image.description="Mullvad VPN app extra binaries build container"
LABEL org.opencontainers.image.licenses=GPL-3.0

RUN apt-get update -y && apt-get install -y \
    git curl wget unzip bzip2 \
    pkg-config make autoconf libtool \
    bison flex \
    gcc \
    gcc-aarch64-linux-gnu \
    gcc-mingw-w64 mingw-w64-common \
    podman \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
