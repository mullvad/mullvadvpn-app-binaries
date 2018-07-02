cd openssl
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars64.bat"
perl Configure VC-WIN64A ^
  no-shared ^
  --prefix=%cd%\..\msvc-openssl ^
  --openssldir=%cd%\..\msvc-openssl ^
  no-seed ^
  no-cast ^
  no-seed ^
  no-cast ^
  no-dso ^
  no-camellia ^
  no-idea ^
  enable-rfc3779 ^
  enable-capieng ^
  -FIWindows.h
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
