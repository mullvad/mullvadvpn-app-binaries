# Custom Mullvad VPN build of OpenVPN

This repository holds our custom OpenVPN binaries , statically linkable OpenSSL
libraries for all of our target platforms, and `libmnl` and `libnftnl` for
Linux, all of which are used in the [Mullvad VPN app].


## Custom changes

The `openvpn` submodule is tracking our [`mullvad-patches`] branch that contain a few custom
changes needed by the [Mullvad VPN app].

## Building
Currently, building is only supported on Debian 9.

### Linux + macOS
Before building, one has to ensure that the build host has all the required
dependencies installed, as outlined in [OpenVPN's buildslave documentation].

Building the OpenVPN binary should be as simple as running `make`, which should produce the binary at
`./build/sbin/openvpn`.

To update the statically linkable OpenSSL library, run `make update_openssl`.

### Windows

Building `openvpn.exe` for Windows is done by cross-compiling from Linux using a mingw-w64
toolchain. You need to do this build on a recent Debian or Ubuntu release, one
should generally follow the instructions laid out in the [OpenVPN's build
system docs].

1. Install the dependencies and cross-compile toolchain:
   ```bash
   ./setup-generic-buildsystem.6.sh
   ```

1. Compile:
   ```bash
   make openvpn/windows
   ```

You should now have the final product in `./build/openvpn/bin/openvpn.exe`

#### Statically linkable OpenSSL
To build the daemon on Windows, one has to build statically linkable OpenSSL libraries.
This requires a few things:
- Perl 5.11 and above (Strawberry Perl distribution works)
- Build Tools for Visual Studio 2017 (a regular installation of Visual Studio
2017 Community Edition works).
- [NASM](https://www.nasm.us/)
To compile OpenSSL for Windows with MSVC, run the following script:
```
build_openssl_msvc.bat
```
The result of a successful build should be newly created `libssl.lib` and
`libcrypto.lib` libraries in `.\windows\` and headers in
`.\windows\include`.

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
