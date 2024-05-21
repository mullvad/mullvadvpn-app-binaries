# Custom third party binaries for the Mullvad VPN app

This repository holds our custom binaries and build scripts for third party software we need to
bundle with the Mullvad VPN app: OpenVPN for our target platforms, `libmnl` and
`libnftnl` for Linux, and Wintun and WireGuardNT for Windows.


## Security and integrity

This repository should conform to the same integrity standards as the main
[Mullvad VPN app] repository, meaning that every merge commit has to be signed.

This repository contains a number of submodules, pulling in the source code for the third party
software we store the binaries for. These submodules must point to commits that are either
directly signed or has a signed tag attached to them. Upon moving a submodule to a different
commit, the new commit must be cryptographically verified.


## Container image

The easiest way to build the binaries is by using the container image specified by `Dockerfile`:

```bash
podman build . -t mullvadvpn-app-binaries
```


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

Repeat the process above for the `openvpn-build`. Note: The upstream tags are not signed in
`openvpn-build`.

### Building on macOS

Before building, one has to ensure that the build host has all the required
dependencies installed:

```bash
brew install automake autoconf libtool pkg-config
```

Building the OpenVPN binary should be as simple as running:

```bash
make openvpn TARGET="aarch64-apple-darwin"
```

or

```bash
make openvpn TARGET="x86_64-apple-darwin"
```

depending on the desired target architecture.

### Building on Linux

Simply run `./container-run.sh make openvpn`.

#### ARM64

Cross-compile on x64 Linux by setting the appropriate `TARGET`:

```bash
./container-run.sh make openvpn TARGET="aarch64-unknown-linux-gnu"
```

### Building for Windows

Building `openvpn.exe` for Windows is done by cross-compiling from Linux using the container image:

1. Compile:
   ```bash
   ./container-run.sh make openvpn_windows
   ```

1. Sign `openvpn.exe` - Do this by copying `openvpn.exe` to the Windows machine with
   the certificate and run the following in *powershell*:
   ```bash
   signtool sign /tr http://timestamp.digicert.com /td sha256 /fd sha256 \
       /d "Mullvad VPN" \
       /du "https://github.com/mullvad/mullvadvpn-app#readme" \
       /f the_certificate.pfx \
       /p <the_certificate.pfx password> \
       openvpn.exe
   ```


## OpenSSL
OpenSSL is a transitive dependency for OpenVPN.
When bumping the submodule to a new OpenSSL release. Make sure to only point to a release tag,
and not a random commit. Also verify that said tag is properly signed by one of the keys listed
here: https://www.openssl.org/community/otc.html


## apisocks5
This is a small SOCKS5 proxy designed to be used in conjunction with the Mullvad VPN app for
accessing the Mullvad API from restricted locations.
See [mullvad/apisocks5](https://github.com/mullvad/apisocks5).

Build instructions:
```bash
# on linux (x86_64)
./container-run.sh make apisocks5 TARGET="x86_64-unknown-linux-gnu"
./container-run.sh make apisocks5 TARGET="aarch64-unknown-linux-gnu"
./container-run.sh make apisocks5 TARGET="x86_64-pc-windows-msvc"
./container-run.sh make apisocks5 TARGET="x86_64-apple-darwin"
./container-run.sh make apisocks5 TARGET="aarch64-apple-darwin"
```


## `libmnl` and `libnftnl`

These libraries are only required for Linux and are required by our app to
apply firewall rules. To produce the required libraries, run `./container-run.sh make libnftnl`.

#### ARM64

Cross-compile both libraries on x64 Linux by setting the appropriate `TARGET`:

```bash
./container-run.sh make libnftnl TARGET="aarch64-unknown-linux-gnu"
```


## libnl

`libnl` is a dependency of OpenVPN, specifically DCO on Linux.
When bumping the submodule, point to a release tag, and verify that the tag is signed by
`49EA7C670E0850E7419514F629C2366E4DFC5728`.


## Updating Wintun

Only applicable to Windows.

Wintun is found in `.\x86_64-pc-windows-msvc\wintun\wintun.dll`. The driver can be downloaded and verified
by running the script `.\wireguard\download-wintun.bat`. This script downloads Wintun, verifies its
checksum, and makes sure that wintun.dll is correctly signed.


## WireGuardNT

Only applicable to Windows.

WireGuardNT can be found in `.\x86_64-pc-windows-msvc\wireguard-nt`. The `wireguard-nt`
submodule contains a [fork](https://github.com/mullvad/wireguard-nt) that fixes multihop tunnels.
To update it, pull the new tag from https://git.zx2c4.com/wireguard-nt, manually verify that the
changes are sensible, and rebase the `mullvad-patches-build` branch on top of it. The new head of
`mullvad-patches-build` should be tagged as `<original tag name>-mullvad`, for example
`0.7-mullvad`. This tag should be signed and pushed to the fork repository.

Follow the instructions in `MULLVAD_BUILD.md` in said submodule to build and sign the driver.


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
[OpenVPN's buildslave documentation]: https://community.openvpn.net/openvpn/wiki/SettingUpBuildslave
