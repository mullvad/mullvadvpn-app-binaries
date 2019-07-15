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
    /opt/android/android-ndk-r20/build/tools/make-standalone-toolchain.sh --platform=android-21 --arch=x86_64 --install-dir=/opt/android/toolchains/android21-x86_64

ENV ANDROID_NDK_HOME="/opt/android/android-ndk-r20"

# Create symlinks to some libraries so that the linker used by Go can find them
RUN for arch in aarch64 x86_64; do \
        for lib in crtbegin_dynamic.o crtend_android.o crtbegin_so.o crtend_so.o; do \
            ln -s "/opt/android/toolchains/android21-${arch}/sysroot/usr/lib/${arch}-linux-android/21/$lib" /opt/android/toolchains/android21-${arch}/sysroot/usr/lib/${arch}-linux-android/; \
        done \
    done

# Install Go-lang
RUN cd /tmp && \
    curl -sf -L -O https://dl.google.com/go/go1.12.4.linux-amd64.tar.gz && \
    test $(sha256sum go1.12.4.linux-amd64.tar.gz | cut -f1 -d' ') = "d7d1f1f88ddfe55840712dc1747f37a790cbcaa448f6c9cf51bbe10aa65442f5" && \
    cd /opt && \
    tar -xzf /tmp/go1.12.4.linux-amd64.tar.gz && \
    rm /tmp/go1.12.4.linux-amd64.tar.gz

ENV PATH=${PATH}:/opt/go/bin

COPY build.sh /usr/local/bin/build.sh

ENTRYPOINT ["/usr/local/bin/build.sh"]
