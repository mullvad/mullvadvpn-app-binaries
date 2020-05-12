
setlocal
mkdir build
set BUILD_DIR=%CD%\build
set TARGET_DIR=%CD%\x86_64-pc-windows-msvc

echo Building libsodium
msbuild libsodium\builds\msvc\vs2019\libsodium.sln /t:Clean /p:Configuration=StaticRelease /p:Platform=x64
msbuild libsodium\builds\msvc\vs2019\libsodium.sln /t:Build /p:Configuration=StaticRelease /p:Platform=x64
copy /y .\libsodium\bin\x64\Release\v142\static\libsodium.lib %BUILD_DIR%\

echo Building shadowsocks
cd shadowsocks-rust
  mkdir .cargo
  copy ..\win-shadowsocks-cargo-config .cargo\config
  CARGO_TARGET_DIR=
  set SODIUM_LIB_DIR=%BUILD_DIR%
  set CARGO_INCREMENTAL="0"
  cargo clean
  cargo +stable build --no-default-features --features sodium --release --bin sslocal
  copy target\release\sslocal.exe %TARGET_DIR%
  rmdir /s /y .cargo\config
cd ..

rmdir /s /y %BUILD_DIR%

endlocal
