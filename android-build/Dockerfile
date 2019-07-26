FROM debian@sha256:75f7d0590b45561bfa443abad0b3e0f86e2811b1fc176f786cd30eb078d1846f

RUN apt-get update -y && apt-get install -y \
    curl \
    file \
    gcc \
    git \
    make \
    python \
    unzip

# Install Android NDK
RUN cd /tmp && \
    curl -sf -L -O https://dl.google.com/android/repository/android-ndk-r20-linux-x86_64.zip && \
    test $(sha256sum android-ndk-r20-linux-x86_64.zip | cut -f1 -d' ') = "57435158f109162f41f2f43d5563d2164e4d5d0364783a9a6fab3ef12cb06ce0" && \
    mkdir /opt/android && \
    cd /opt/android && \
    unzip -q /tmp/android-ndk-r20-linux-x86_64.zip && \
    rm /tmp/android-ndk-r20-linux-x86_64.zip && \
    mkdir toolchains && \
    /opt/android/android-ndk-r20/build/tools/make-standalone-toolchain.sh --platform=android-21 --arch=arm64 --install-dir=/opt/android/toolchains/android21-aarch64 && \
    /opt/android/android-ndk-r20/build/tools/make-standalone-toolchain.sh --platform=android-21 --arch=x86_64 --install-dir=/opt/android/toolchains/android21-x86_64 && \
    /opt/android/android-ndk-r20/build/tools/make-standalone-toolchain.sh --platform=android-21 --arch=arm --install-dir=/opt/android/toolchains/android21-armv7 && \
    /opt/android/android-ndk-r20/build/tools/make-standalone-toolchain.sh --platform=android-21 --arch=x86 --install-dir=/opt/android/toolchains/android21-i686

ENV ANDROID_NDK_HOME="/opt/android/android-ndk-r20"

# Create symlinks to some libraries so that the linker used by Go can find them
RUN for arch in aarch64 x86_64 i686 armv7; do \
        if [ "$arch" = "armv7" ]; then \
            TARGET="arm-linux-androideabi"; \
        else \
            TARGET="${arch}-linux-android"; \
        fi; \
        \
        for lib in crtbegin_dynamic.o crtend_android.o crtbegin_so.o crtend_so.o; do \
            ln -s "/opt/android/toolchains/android21-${arch}/sysroot/usr/lib/${TARGET}/21/$lib" /opt/android/toolchains/android21-${arch}/sysroot/usr/lib/${TARGET}/; \
        done \
    done

# Install Go-lang
RUN cd /tmp && \
    curl -sf -L -O https://dl.google.com/go/go1.12.7.linux-amd64.tar.gz && \
    test $(sha256sum go1.12.7.linux-amd64.tar.gz | cut -f1 -d' ') = "66d83bfb5a9ede000e33c6579a91a29e6b101829ad41fffb5c5bb6c900e109d9" && \
    cd /opt && \
    tar -xzf /tmp/go1.12.7.linux-amd64.tar.gz && \
    rm /tmp/go1.12.7.linux-amd64.tar.gz

ENV PATH=${PATH}:/opt/go/bin

COPY build.sh /usr/local/bin/build.sh

ENTRYPOINT ["/usr/local/bin/build.sh"]
