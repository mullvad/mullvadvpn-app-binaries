# Custom third party binaries for the Mullvad VPN app
This repository holds our custom OpenVPN binaries, statically linkable OpenSSL
libraries for all of our target platforms, and `libmnl` and `libnftnl` for
Linux, all of which are used in the [Mullvad VPN app].



## Custom changes

The `openvpn` submodule is tracking our [`mullvad-patches`] branch that contain a few custom
changes needed by the [Mullvad VPN app].



## Building OpenVPN

### Linux + macOS
Before building, one has to ensure that the build host has all the required
dependencies installed, as outlined in [OpenVPN's buildslave documentation].

Building the OpenVPN binary should be as simple as running `make openvpn`.


#### Linux
Currently, the Linux distro of choice for building OpenVPN currently is Debian
9, issues have been experienced on other distributions.


### Windows
Building `openvpn.exe` for Windows is done by cross-compiling from Linux using
a mingw-w64 toolchain. You need to do this build on a recent Debian or Ubuntu
release, one should generally follow the instructions laid out in the
[OpenVPN's build system docs]. Currently, this has only been tested with Debian 9.


1. Install the dependencies and cross-compile toolchain:
   ```bash
   ./setup-generic-buildsystem.6.sh
   ```

1. Compile:
   ```bash
   make openvpn_windows
   ```

You should now have the final product in `./build/openvpn/bin/openvpn.exe`



## Building Wireguard-Go
The userspace implementation of Wireguard using Go is used in the app. For Linux and macOS, a static
library must be built to include support for Wireguard, while in Android a shared library is built
from the official Wireguard app for Android [repository][wireguard-android].

[wireguard-android]: https://github.com/WireGuard/wireguard-android/

### Android
The libwg-go.so shared library is cross-compiled using a custom Docker image. You can build the
image with the final binaries and extract them to the appropriate sub-directory in the repository
using the following command:

```bash
make android
```

### Linux + macOS
Building the wireugard-go static library requires only a go compiler, the
version used at the time of writing is `go1.12.7`.

### Windows
Currently, Windows is not supported.



## Building OpenSSL
To build the MullvadVPN app, one has to have statically linkable OpenSSL libraries.

### Android
The OpenSSL static binaries are cross-compiled using a custom Docker image. You can build the image
with the final binaries and extract them to the appropriate sub-directory in the repository using
the following command:

```bash
make android
```

### Linux + macOS
To build statically linkable OpenSSL libraries on macOS and Linux, just run
`make update_openssl`. To do so, one has to make sure to have all the required
build dependencies on the build host. Refer to OpenSSL's documentation, but
usually it requires a recent version of Perl 5 and a good C compiler and
standard library.


### Windows
Building a static OpenSSL library on Windows requires the following:
- Perl 5.11 and above (Strawberry Perl distribution works)
- Build Tools for Visual Studio 2017-2019 (a regular installation of Visual Studio
2017-2019 Community Edition works).
- [NASM](https://www.nasm.us/), make sure that the tools are in your PATH.
If installed with `chocolatey`, to set it up for your current shell, just run
the batch script in `C:\Program Files\NASM\nasmpath.bat`.

To compile OpenSSL for Windows with MSVC, run the following script from a
a _x64 Native Tools Command Prompt for VSXXXX_:
```
build-openssl-with-msbvc.bat
```
The result of a successful build should be newly created `libssl.lib` and
`libcrypto.lib` libraries in `.\x86_64-pc-windows-msvc\` and headers in
`.\x86_64-pc-windows-msvc\include`.

#### Troubleshooting

* Missing `ltmain.sh`? Copy it from the libtool installation path into openvpn/



## `libmnl` and `libnftnl`
These libraries are only required for Linux and are required by our app to
apply firewall rules. To produce the required libraries, run `make libnftnl`.



## Building libsodium
Libsodium is used by e.g. Shadowsocks, a proxy software bundled with the MullvadVPN app.

### Linux + MacOS
???

### Windows
When wishing to build libsodium on Windows it's recommended that you use one of the prepared
Visual Studio solutions. E.g. for building a statically linkable libsodium, using Visual Studio 2017
Community Edition, pick the solution file at `.\libsodium\builds\msvc\vs2017\libsodium.sln`.
Inside the solution, select the (`StaticRelease`, `x64`) configuration.

The static library is created as: `.\libsodium\bin\x64\Release\v141\static\libsodium.lib`.



## Building Shadowsocks

### Linux + MacOS
`make shadowsocks`

### Windows
If using `Git Bash`, you first need to install `make`. You can use `make` from `ezwinports`,
e.g. `make-4.2.1-without-guile-w32-bin.zip`. Extract and merge the archive's contents into:
`C:\Program Files\git\mingw64`.

Next, temporarily modify `shadowsocks-rust` to statically link as many dependencies as possible.
Create `.\shadowsocks-rust\.cargo\config` with the following content:

```
[target.x86_64-pc-windows-msvc]
rustflags = ["-Ctarget-feature=+crt-static"]
```

Temporarily rename `.\x86_64-pc-windows-msvc\libsodium.lib` into
`.\x86_64-pc-windows-msvc\sodium.lib`. This allows us to work around a bug in the `libsodium-ffi`
crate.

Then run `make shadowsocks` and wait for it to build. You'll notice the make process is aborted
when it comes to `strip`, but this is fine, as `strip` is not available nor applicable in this case.

Grab the built binary from `.\shadowsocks-rust\target\release\sslocal.exe`



## Building a custom Wintun installer

Only applicable to Windows.

We have a need to build a branded `MSI` installer from the official `MSM` that is provided by the
Wintun project. This is done using the files found under `x86_64-pc-windows-msvc\wintun`.

`mullvad-wintun.wxs` defines the `MSI` project.

`build.bat` fetches all the required dependencies, then builds and optionally signs the `MSI`.
It's expected that this file will need to be updated from time to time whenever a new version
of Wintun is released, since it downloads a specific version of Wintun.

`build-signed.bat` configures the environment so the MSI is signed after having been built. The
certificate used is our primary `Amagicom AB` certificate for code signing. This is the build
script that should always be used outside of testing.



## Storage of binaries

This repository, apart from having the scripts used to build OpenVPN, also holds the built binaries
for the platforms we need. These exist under directories named after the target triplet they are
intended for.


[Mullvad VPN app]: https://github.com/mullvad/mullvadvpn-app
[`mullvad-patches`]: https://github.com/mullvad/openvpn/tree/mullvad-patches
[OpenVPN's build system docs]: https://community.openvpn.net/openvpn/wiki/SettingUpGenericBuildsystem
[OpenVPN's buildslave documentation]: https://community.openvpn.net/openvpn/wiki/SettingUpBuildslave
