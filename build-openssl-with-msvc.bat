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
cd ..

:: Copy the libraries
copy /y openssl\libssl.lib x86_64-pc-windows-msvc\libssl.lib
copy /y openssl\libcrypto.lib x86_64-pc-windows-msvc\libcrypto.lib

:: Copy headers
copy /y openssl\include\openssl\opensslconf.h x86_64-pc-windows-msvc\include\openssl\
copy /y openssl\include\openssl\opensslv.h x86_64-pc-windows-msvc\include\openssl\
