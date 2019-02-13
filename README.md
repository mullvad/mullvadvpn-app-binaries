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
Building the wireugard-go static library requires only a go compiler, the
version used at the time of writing is `go1.11.2`.

Currently, only MacOS and Linux are supported.

## Building OpenSSL
To build the MullvadVPN app, one has to have statically linkable OpenSSL libraries.

### Linux + macOS
To build statically linkable OpenSSL libraries on macOS and Linux, just run
`make update_openssl`. To do so, one has to make sure to have all the required
build dependencies on the build host. Refer to OpenSSL's documentation, but
usually it requires a recent version of Perl 5 and a good C compiler and
standard library.


### Windows
Building a static OpenSSL library on Windows requires the following:
- Perl 5.11 and above (Strawberry Perl distribution works)
- Build Tools for Visual Studio 2017 (a regular installation of Visual Studio
2017 Community Edition works).
- [NASM](https://www.nasm.us/)

To compile OpenSSL for Windows with MSVC, run the following script:
```
build-openssl-with-msbvc.bat
```
The result of a successful build should be newly created `libssl.lib` and
`libcrypto.lib` libraries in `.\windows\` and headers in
`.\windows\include`.

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

## Storage of binaries

This repository, apart from having the scripts used to build OpenVPN, also holds the built binaries
for the platforms we need. These exist under directories for each platform:
* `macos/`
* `linux/`
* `windows/`


[Mullvad VPN app]: https://github.com/mullvad/mullvadvpn-app
[`mullvad-patches`]: https://github.com/mullvad/openvpn/tree/mullvad-patches
[OpenVPN's build system docs]: https://community.openvpn.net/openvpn/wiki/SettingUpGenericBuildsystem
[OpenVPN's buildslave documentation]: https://community.openvpn.net/openvpn/wiki/SettingUpBuildslave
