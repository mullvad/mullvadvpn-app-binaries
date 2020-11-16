@echo off
setlocal

set SIG_THUMBPRINT=DF98E075A012ED8C86FBCF14854B8F9555CB3D45
set DEST_DIR=%~dp0%..\x86_64-pc-windows-msvc

:getwintun
	rmdir /s /q .deps 2> NUL
	mkdir .deps || goto :error
	cd .deps || goto :error
	call :download wintun-0.9.zip https://www.wintun.net/builds/wintun-0.9.zip ef435b3c26fdb3bd79dd3f27f4e0020af1733e6cd186c93072dd540a13fcd53e || goto :error
	echo [+] Extracting wintun.dll
	tar -xf wintun-0.9.zip || goto :error
	cd .. || goto :error

:verify
	echo [+] Verifying wintun.dll signature
	signtool verify /v /pa .deps\wintun\bin\amd64\wintun.dll || goto :error
	for /f %%a in ('powershell -command "(Get-AuthenticodeSignature -FilePath .deps\wintun\bin\amd64\wintun.dll).SignerCertificate.Thumbprint"') ^
do if not "%%a"=="%SIG_THUMBPRINT%" goto :thumbprinterror

:movefile
	echo [+] Copying wintun.dll to %DEST_DIR%
	move /y .deps\wintun\bin\amd64\wintun.dll %DEST_DIR%\wintun.dll || goto :error

:cleanup
	echo [+] Cleaning up temporary files
	rmdir /s /q .deps 2> NUL

:success
	echo [+] Success.
	exit /b 0

:download
	echo [+] Downloading %1
	curl -#fLo %1 %2 || exit /b 1
	echo [+] Verifying %1
	for /f %%a in ('CertUtil -hashfile %1 SHA256 ^| findstr /r "^[0-9a-f]*$"') do if not "%%a"=="%~3" exit /b 1
	goto :eof

:thumbprinterror
	echo [-] Failed: Unexpected signature
	exit /b 1

:error
	echo [-] Failed with error #%errorlevel%.
	cmd /c exit %errorlevel%