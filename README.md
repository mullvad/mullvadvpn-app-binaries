# Custom third party binaries for the Mullvad VPN app

This repository holds our custom binaries and build scripts for third party software we need to
bundle with the Mullvad VPN app: `libmnl` and `libnftnl` for Linux, and Wintun and WireGuardNT
for Windows.


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


## `libmnl` and `libnftnl`

These libraries are only required for Linux and are required by our app to
apply firewall rules. To produce the required libraries, run `./container-run.sh make libnftnl`.

#### ARM64 and RISC-V

Cross-compile both libraries on x64 Linux by setting the appropriate `TARGET`:

```bash
git submodule update --init
./container-run.sh make libnftnl TARGET="aarch64-unknown-linux-gnu"
./container-run.sh make libnftnl TARGET="riscv64gc-unknown-linux-gnu"
```

## Build without container image

```bash
sudo apt-get install make autoconf libtool pkg-config gcc
git submodule update --init
make libnftnl
```


## Updating Wintun

Only applicable to Windows.

Wintun is found in `.\<arch>-pc-windows-msvc\wintun\wintun.dll`. The driver can be downloaded and verified
by running the script `.\wireguard\download-wintun.cmd`. This script downloads Wintun, verifies its
checksum, and makes sure that wintun.dll is correctly signed.


## WireGuardNT

Only applicable to Windows.


WireGuardNT is found in `.\<arch>-pc-windows-msvc\wireguard-nt`. The driver can be downloaded and verified
by running the script `.\wireguard\download-wireguard.cmd`. This script downloads WireGuardNT, verifies its
checksum, and makes sure that wireguard.dll is correctly signed.


## Split tunnel driver

Only applicable to Windows.

The split tunneling functionality implemented in [Mullvad VPN app] is supported by a custom kernel driver.
The driver is developed by us, and is represented here as a submodule named `win-split-tunnel`.

Instructions for building and signing the driver are provided in said submodule.

The built and signed driver, and associated files, reside under `<arch>\split-tunnel`.


## Storage of binaries

This repository holds the built binaries for the platforms we need. These exist under directories
named after the target triplet they are intended for.


[Mullvad VPN app]: https://github.com/mullvad/mullvadvpn-app
