# WireGuard wrapper on Windows

## Build wrapper as DLL

(GOARCH=amd64 to ensure 64-bit artifact)

`go build -v -o libwg.dll -buildmode c-shared`

## Prepare DEF file

`dumpbin /exports libwg.dll > exports.def`

Then fix up the file to have this format:

```
LIBRARY libwg
EXPORTS
  function_1
  function_n
```

Do **not** include ordinals in the DEF file. This will break linking at a later stage.

## Generate import library from DEF file

`lib /def:exports.def /out:libwg.lib /machine:X64`


## Package

Copy `libwg.dll` and `libwg.lib` into `../x86_64-pc-windows-msvc/wireguard`.
