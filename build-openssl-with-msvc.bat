cd openssl

set OPENSSL_CONFIG =   enable-capieng ^
  enable-rfc3779 ^
  no-camellia ^
  no-cast ^
  no-dso ^
  no-idea ^
  no-seed ^
  no-shared ^

:: Sourcing environment form Visual Studio to be able to compile with MSVC and
:: all the system libraries and headers
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars64.bat"

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
copy /y openssl\libssl.lib x86_64-pc-windows-msvc\
copy /y openssl\libcrypto.lib x86_64-pc-windows-msvc\
:: Copy headers
copy /y openssl\include\openssl\opensslconf.h x86_64-pc-windows-msvc\include\openssl\
copy /y openssl\include\openssl\opensslv.h x86_64-pc-windows-msvc\include\openssl\
