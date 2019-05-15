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
    curl -sf -L -O https://dl.google.com/android/repository/android-ndk-r19b-linux-x86_64.zip && \
    test $(sha256sum android-ndk-r19b-linux-x86_64.zip | cut -f1 -d' ') = "0fbb1645d0f1de4dde90a4ff79ca5ec4899c835e729d692f433fda501623257a" && \
    mkdir /opt/android && \
    cd /opt/android && \
    unzip -q /tmp/android-ndk-r19b-linux-x86_64.zip && \
    rm /tmp/android-ndk-r19b-linux-x86_64.zip && \
    mkdir toolchains && \
    /opt/android/android-ndk-r19b/build/tools/make-standalone-toolchain.sh --platform=android-28 --arch=arm64 --install-dir=/opt/android/toolchains/android28-aarch64

ENV ANDROID_SYSROOT="/opt/android/toolchains/android28-aarch64/sysroot" \
    ANDROID_LLVM_TRIPLE="aarch64-linux-android" \
    ANDROID_C_COMPILER="/opt/android/toolchains/android28-aarch64/bin/aarch64-linux-android28-clang" \
    ANDROID_NDK_HOME="/opt/android/" \
    ANDROID_TOOLCHAIN_ROOT="/opt/android/toolchains/android28-aarch64" \
    ANDROID_ARCH_NAME="arm64"

# Create symlinks to some libraries so that the linker used by Go can find them
RUN for lib in crtbegin_dynamic.o crtend_android.o crtbegin_so.o crtend_so.o; do \
        ln -s "/opt/android/toolchains/android28-aarch64/sysroot/usr/lib/aarch64-linux-android/28/$lib" /opt/android/toolchains/android28-aarch64/sysroot/usr/lib/aarch64-linux-android/; \
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
