# Custom third party binaries for the Mullvad VPN app

This repository holds our custom binaries and build scripts for third party software we need to
bundle with the Mullvad VPN app: OpenVPN and Shadowsocks for our target platforms, `libmnl` and
`libnftnl` for Linux, and Wintun and WireGuardNT for Windows.


## Security and integrity

This repository should conform to the same integrity standards as the main
[Mullvad VPN app] repository, meaning that every merge commit has to be signed.

This repository contains a number of submodules, pulling in the source code for the third party
software we store the binaries for. These submodules must point to commits that are either
directly signed or has a signed tag attached to them. Upon moving a submodule to a different
commit, the new commit must be cryptographically verified.


## OpenVPN

The `openvpn` submodule is tracking our [`mullvad-patches`] branch that contain a few custom
changes needed by the [Mullvad VPN app].

### Updating OpenVPN

When bumping the submodule (rebasing `mullvad-patches`) to a new OpenVPN release. Make sure
the upstream release tag is properly signed by the following gpg key:

```
B62E6A2B4E56570B7BDC6BE01D829EFECA562812
```

Then tag the new head of `mullvad-patches` as `<original tag name>-mullvad`, for example
`v2.4.8-mullvad`. This tag should be signed and pushed to our fork repository.

### Building on Linux + macOS

Before building, one has to ensure that the build host has all the required
dependencies installed, as outlined in [OpenVPN's buildslave documentation].

Building the OpenVPN binary should be as simple as running `make openvpn`.

#### Linux

Currently, the Linux distro of choice for building OpenVPN currently is Debian
9, issues have been experienced on other distributions.

#### Building for ARM macOS

Building for Apple Silicon macOS is done by cross-compiling from Intel macOS by adding the `TARGET="aarch64-apple-darwin"` option, i.e.:
```bash
make openvpn TARGET="aarch64-apple-darwin"
```

### Building for Windows

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

1. Sign `openvpn.exe` - Do this by copying `openvpn.exe` to the Windows machine with
   the certificate and run:
   ```bash
   signtool sign /tr http://timestamp.digicert.com /td sha256 /fd sha256 \
       /d "Mullvad VPN" \
       /du "https://github.com/mullvad/mullvadvpn-app#readme" \
       /f the_certificate.pfx \
       /p <the_certificate.pfx password> \
       openvpn.exe
   ```



## OpenSSL
OpenSSL is a transitive dependency for Shadowsocks and OpenVPN.
When bumping the submodule to a new OpenSSL release. Make sure to only point to a release tag,
and not a random commit. Also verify that said tag is properly signed by the following gpg key:

```
8657ABB260F056B1E5190839D9C4D26D0E604491
```

## `libmnl` and `libnftnl`

These libraries are only required for Linux and are required by our app to
apply firewall rules. To produce the required libraries, run `make libnftnl`.



## Building libsodium

Libsodium is used by e.g. Shadowsocks, a proxy software bundled with the MullvadVPN app.

When updating the `libsodium` submodule. Only point it to a proper release tag, and verify that
said tag is properly signed with the following key:

```
54A2B8892CC3D6A597B92B6C210627AABA709FE1
```


## Building Shadowsocks

### Linux + MacOS
To build Shadowsocks, just run `make shadowsocks_linux` or `make shadowsocks_macos` respectively.

#### Building for ARM macOS

Building for Apple Silicon macOS is done by cross-compiling from Intel macOS by adding the `TARGET="aarch64-apple-darwin"` option, i.e.:
```bash
make shadowsocks_macos TARGET="aarch64-apple-darwin"
```

### Windows

To build Shadowsocks, just run `shadowsocks-windows.bat` from a command prompt that has the Visual
Studio 2019 build tool environment. The script will compile `libsodium` statically and
then build Shadowsocks with said library.

Remember to sign the binary! See OpenVPN build instructions for the command

Dependencies for building Shadowsocks:
- Build Tools for Visual Studio 2019 (a regular installation of Visual Studio
  2019 Community Edition works).


## Updating Wintun

Only applicable to Windows.

Wintun is found in `.\x86_64-pc-windows-msvc\wintun\wintun.dll`. The driver can be downloaded and verified
by running the script `.\wireguard\download-wintun.bat`. This script downloads Wintun, verifies its
checksum, and makes sure that wintun.dll is correctly signed.


## Updating WireGuardNT

Only applicable to Windows.

WireGuardNT is found in `.\x86_64-pc-windows-msvc\wireguard-nt`. The driver can be downloaded and verified
by running the script `.\wireguard\download-wireguard-nt.bat`.


## Split tunnel driver

Only applicable to Windows.

The split tunneling functionality implemented in [Mullvad VPN app] is supported by a custom kernel driver.
The driver is developed by us, and is represented here as a submodule named `win-split-tunnel`.

Instructions for building and signing the driver are provided in said submodule.

The built and signed driver, and associated files, reside under `x86_64-pc-windows-msvc\split-tunnel`.


## Storage of binaries

This repository, apart from having the scripts used to build OpenVPN, also holds the built binaries
for the platforms we need. These exist under directories named after the target triplet they are
intended for.


[Mullvad VPN app]: https://github.com/mullvad/mullvadvpn-app
[`mullvad-patches`]: https://github.com/mullvad/openvpn/tree/mullvad-patches
[OpenVPN's build system docs]: https://community.openvpn.net/openvpn/wiki/SettingUpGenericBuildsystem
[OpenVPN's buildslave documentation]: https://community.openvpn.net/openvpn/wiki/SettingUpBuildslave
