# Custom Mullvad VPN build of OpenVPN

This repository holds our custom OpenVPN binaries used in the [Mullvad VPN app].

## Custom changes

The `openvpn` submodule is tracking our [`mullvad-patches`] branch that contain a few custom
changes needed by the [Mullvad VPN app].

## Building

### Linux + macOS

Building the binary should be as simple as running `make`, which should produce the binary at
`./build/sbin/openvpn`.

### Windows

Building `openvpn.exe` for Windows is done by cross-compiling from Linux using a mingw-w64
toolchain. You need to do this build on a recent Debian or Ubuntu release.

1. Install the dependencies and cross-compile toolchain:
   ```bash
   ./setup-generic-buildsystem.6.sh
   ```

1. Compile:
   ```bash
   make windows
   ```

You should now have the final product in `./build/openvpn/bin/openvpn.exe`

## Storage of binaries

This repository, apart from having the scripts used to build OpenVPN, also holds the built binaries
for the platforms we need. These exist under directories for each platform:
* `macos/`
* `linux/`
* `windows/`


[Mullvad VPN app]: https://github.com/mullvad/mullvadvpn-app
[`mullvad-patches`]: https://github.com/mullvad/openvpn/tree/mullvad-patches
