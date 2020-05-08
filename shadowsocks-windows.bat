
setlocal
mkdir build
set BUILD_DIR=%CD%\build
set TARGET_DIR=%CD%\x86_64-pc-windows-msvc

echo Building libsodium
msbuild libsodium\builds\msvc\vs2019\libsodium.sln /t:Clean /p:Configuration=StaticRelease /p:Platform=x64
msbuild libsodium\builds\msvc\vs2019\libsodium.sln /t:Build /p:Configuration=StaticRelease /p:Platform=x64
copy /y .\libsodium\bin\x64\Release\v142\static\libsodium.lib %BUILD_DIR%\sodium.lib

echo Building openssl
cd openssl
  set OPENSSL_CONFIG=enable-capieng ^
    enable-rfc3779 ^
    no-ssl3 ^
    no-camellia ^
    no-cast ^
    no-dso ^
    no-idea ^
    no-shared ^
    no-seed

  perl Configure VC-WIN64A ^
    --prefix=%cd%\..\msvc-openssl ^
    --openssldir=%cd%\..\msvc-openssl ^
    %OPENSSL_CONFIG% ^
    -FIWindows.h

  nmake clean
  nmake build_generated
  nmake build_libs_nodep
  copy /y libssl.lib %BUILD_DIR%
  copy /y libcrypto.lib %BUILD_DIR%
  mkdir %BUILD_DIR%\include\openssl
  copy /y include\openssl\opensslconf.h %BUILD_DIR%\include\openssl\
  copy /y include\openssl\opensslv.h %BUILD_DIR%\include\openssl\
cd ..

echo Building shadowsocks
cd shadowsocks-rust
  mkdir .cargo
  copy ..\win-shadowsocks-cargo-config .cargo\config
  CARGO_TARGET_DIR=
  set SODIUM_STATIC="1"
  set SODIUM_LIB_DIR=%BUILD_DIR%
  set OPENSSL_STATIC="1"
  set OPENSSL_LIB_DIR=%BUILD_DIR%
  set OPENSSL_INCLUDE_DIR=%BUILD_DIR%\include
  set CARGO_INCREMENTAL="0"
  cargo clean
  cargo +stable build --no-default-features --features sodium --release --bin sslocal
  copy target\release\sslocal.exe %TARGET_DIR%
  rmdir /s /y .cargo\config
cd ..

rmdir /s /y %BUILD_DIR%

endlocal
