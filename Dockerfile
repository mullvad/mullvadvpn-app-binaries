# To build the image:
# podman build . -t mullvadvpn-app-binaries

# Debian 11 is the oldest supported distro. It has the oldest glibc that we support.
# This checksum points to a 11.6-slim image.
FROM debian@sha256:77f46c1cf862290e750e913defffb2828c889d291a93bdd10a7a0597720948fc

LABEL org.opencontainers.image.source=https://github.com/mullvad/mullvadvpn-app-binaries
LABEL org.opencontainers.image.description="Mullvad VPN app extra binaries build container"
LABEL org.opencontainers.image.licenses=GPL-3.0

# Install packages from a fixed point in time on snapshot.debian.org, so that every build of
# this image installs the exact same package versions. This helps make the image reproducible.
# Bump the timestamp to pick up newer packages. snapshot.debian.org resolves it to the latest
# snapshot taken at or before that time, separately for each archive.
# The current timestamp is after the final Debian 11 LTS security update.
ARG DEBIAN_SNAPSHOT=20260901T000000Z
COPY setup-debian-snapshot.sh /tmp/
RUN /tmp/setup-debian-snapshot.sh && rm /tmp/setup-debian-snapshot.sh

RUN apt-get update -y && apt-get install -y \
    git curl wget unzip bzip2 \
    pkg-config make autoconf libtool \
    bison flex \
    gcc \
    gcc-aarch64-linux-gnu \
    gcc-riscv64-linux-gnu \
    gcc-mingw-w64 mingw-w64-common \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
