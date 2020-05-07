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
  --prefix=%cd%\..\build ^
  --openssldir=%cd%\..\build ^
  %OPENSSL_CONFIG% ^
  -FIWindows.h

nmake clean
nmake build_generated
nmake build_libs_nodep
cd ..
