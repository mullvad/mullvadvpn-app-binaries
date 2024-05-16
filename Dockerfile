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
RUN if [ "$(uname -m)" = "x86_64" ]; then \
        curl -fLO https://go.dev/dl/go1.22.3.linux-amd64.tar.gz &&\
        echo "8920ea521bad8f6b7bc377b4824982e011c19af27df88a815e3586ea895f1b36  go1.22.3.linux-amd64.tar.gz" \
            | sha256sum --check - && \
        tar -C /usr/local/ -xzf go1.22.3.linux-amd64.tar.gz; \
    elif [ "$(uname -m)" = "aarch64" ]; then \
        curl -fLO https://go.dev/dl/go1.22.3.linux-arm64.tar.gz &&\
        echo "6c33e52a5b26e7aa021b94475587fce80043a727a54ceb0eee2f9fc160646434  go1.22.3.linux-arm64.tar.gz" \
            | sha256sum --check - && \
        tar -C /usr/local/ -xzf go1.22.3.linux-arm64.tar.gz; \
    fi
ENV PATH=$PATH:/usr/local/go/bin
RUN go version

WORKDIR /build
