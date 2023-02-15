#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

podman run --rm -it \
    -v .:/build:O \
    -v ./x86_64-pc-windows-msvc:/build/x86_64-pc-windows-msvc:Z \
    -v ./x86_64-unknown-linux-gnu:/build/x86_64-unknown-linux-gnu:Z \
    -v ./aarch64-unknown-linux-gnu:/build/aarch64-unknown-linux-gnu:Z \
    mullvadvpn-app-binaries /bin/sh -c "$1"
