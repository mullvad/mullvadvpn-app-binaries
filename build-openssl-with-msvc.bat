cd openssl

set OPENSSL_CONFIG =   enable-capieng ^
  enable-rfc3779 ^
  no-camellia ^
  no-cast ^
  no-dso ^
  no-idea ^
  no-seed ^
  no-shared ^
  -FIWindows.h
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars64.bat"
perl Configure VC-WIN64A ^
  --prefix=%cd%\..\msvc-openssl ^
  --openssldir=%cd%\..\msvc-openssl ^
  %OPENSSL_CONFIG%

nmake clean
nmake build_generated
nmake build_libs_nodep
cd ..
:: Copy the libraries
copy /y openssl\libssl.lib windows\
copy /y openssl\libcrypto.lib windows\
:: Copy headers
copy /y openssl\include\openssl\opensslconf.h windows\include\openssl\
copy /y openssl\include\openssl\opensslv.h windows\include\openssl\
