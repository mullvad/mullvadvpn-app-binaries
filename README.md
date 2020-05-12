# Custom third party binaries for the Mullvad VPN app

This repository holds our custom binaries and build scripts for third party software we need to
bundle with the Mullvad VPN app: OpenVPN and Shadowsocks for our target platforms, `libmnl` and
`libnftnl` for Linux, WinTun and TAP adapter drivers for Windows.


## Security and integrity

This repository should conform to the same integrity standards as the main
[Mullvad VPN app] repository. Meaning every merge commit has to be signed.

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




## TAP adapter driver for Windows 8-10

On Windows, we build our own fork of OpenVPN's TAP driver (tracking branch `mullvad` in the
submodule `tap-windows6`). This is to prevent conflicts with other software that relies on OpenVPN.

### Dependencies

* Visual Studio 2019 (e.g. Build Tools)
* Spectre-mitigated MSVC libraries (available in the VS installer)
* Python 3
* [WDK](https://docs.microsoft.com/en-us/windows-hardware/drivers/download-the-wdk) for Windows 10

### Build and sign the driver
As of now, only the driver for amd64 is in use by Mullvad VPN, so builds for other architectures
are skipped.

1. Open `x64 Native Tools Command Prompt for VS 2019`.

1. Run (from the `tap-windows6` directory):
   ```
   build.bat <cert_sha1_hash>
   ```

   `cert_sha1_hash` refers to the SHA1 hash of the signing certificate. The certificate should be
   available in the certificate store, where the hash may be referred to as "thumbprint". It can
   be viewed by running `certmgr.msc` or `certlm.msc`.

This produces a signed TAP driver in `.\tap-windows6\dist\amd64`. This will work on Windows 8.x.
A cab file is also created, `.\tap-windows6\dist\tap-windows6-amd64.cab`, which must be submitted
to the [Windows Hardware Dev Center](https://developer.microsoft.com/en-us/windows/hardware) for
attestation signing. The attestation-signed driver package must be used for Windows 10 but will
not work for Windows 8.1 or earlier.

## TAP adapter driver for Windows 7

An older NDIS 5 driver is used on Windows 7 due to issues with [packet loss](https://github.com/OpenVPN/tap-windows6/issues/58).
This is found in the `tap-windows` submodule.

### Dependencies

* Visual Studio 2019 (e.g. Build Tools)
* [WDK](https://docs.microsoft.com/en-us/windows-hardware/drivers/download-the-wdk) for Windows 10

### Build and sign the driver
As of now, only the driver for amd64 is in use by Mullvad VPN, so builds for other architectures
are skipped.

1. Open `x64 Native Tools Command Prompt for VS 2019` and navigate to the `tap-windows` directory.

1. Run `configure.bat`.

1. Run:
   ```
   build.bat <cert_sha1_hash>
   ```

   `cert_sha1_hash` refers to the SHA1 hash of the signing certificate. The certificate should be
   available in the certificate store, where the hash may be referred to as "thumbprint". It can
   be viewed by running `certmgr.msc` or `certlm.msc`.

The driver files can be found in `.\tap-windows\src\x64\Release\tap-windows`.


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

### Windows

To build Shadowsocks, just run `shaodwsocks-windows.bat` from a command prompt that has the Visual
Studio 2019 build tool environment. The script will compile `libsodium` statically and
then build Shadowsocks with said library.

Dependencies for building Shadowsocks:
- Build Tools for Visual Studio 2019 (a regular installation of Visual Studio
  2019 Community Edition works).


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
