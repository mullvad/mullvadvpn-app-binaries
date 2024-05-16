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
    && rm -rf /var/lib/apt/lists/*


# Install the Go compiler
ENV PATH=$PATH:/usr/local/go/bin
ENV GO_FILENAME=go1.22.3.linux-amd64.tar.gz
ENV GO_FILEHASH=8920ea521bad8f6b7bc377b4824982e011c19af27df88a815e3586ea895f1b36
RUN curl -fLO https://go.dev/dl/${GO_FILENAME} &&\
    echo "${GO_FILEHASH}  ${GO_FILENAME}" | sha256sum --check - &&\
    tar -C /usr/local/ -xzf go1.22.3.linux-amd64.tar.gz &&\
    go version

WORKDIR /build
