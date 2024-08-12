#!/usr/bin/env bash

# This script assumes that the image from the Dockerfile in this directory
# is built and is tagged as mullvadvpn-app-binaries.

set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

set -x
exec podman run --rm -it \
    -v "${SCRIPT_DIR}":/build:O \
    -v "${SCRIPT_DIR}/x86_64-pc-windows-msvc":/build/x86_64-pc-windows-msvc:Z \
    -v "${SCRIPT_DIR}/aarch64-pc-windows-msvc":/build/aarch64-pc-windows-msvc:Z \
    -v "${SCRIPT_DIR}/x86_64-unknown-linux-gnu":/build/x86_64-unknown-linux-gnu:Z \
    -v "${SCRIPT_DIR}/aarch64-unknown-linux-gnu":/build/aarch64-unknown-linux-gnu:Z \
    -v "${SCRIPT_DIR}/aarch64-apple-darwin":/build/aarch64-apple-darwin:Z \
    -v "${SCRIPT_DIR}/x86_64-apple-darwin":/build/x86_64-apple-darwin:Z \
    mullvadvpn-app-binaries /bin/sh -c -- "$*"
