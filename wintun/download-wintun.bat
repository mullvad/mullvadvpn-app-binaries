@echo off
setlocal

set SIG_THUMBPRINT=DF98E075A012ED8C86FBCF14854B8F9555CB3D45
set DEST_DIR=%~dp0%..\x86_64-pc-windows-msvc\wintun

:getwintun
	rmdir /s /q .deps 2> NUL
	mkdir .deps || goto :error
	cd .deps || goto :error
	call :download wintun.zip https://www.wintun.net/builds/wintun-0.13.zip 34afe7d0de1fdb781af3defc0a75fd8c97daa756279b42dd6be6a1bd8ccdc7f0 || goto :error
	echo [+] Extracting wintun.dll
	tar -xf wintun.zip || goto :error
	cd .. || goto :error

:verify
	echo [+] Verifying wintun.dll signature
	signtool verify /v /pa .deps\wintun\bin\amd64\wintun.dll || goto :error
	for /f %%a in ('powershell -command "(Get-AuthenticodeSignature -FilePath .deps\wintun\bin\amd64\wintun.dll).SignerCertificate.Thumbprint"') ^
do if not "%%a"=="%SIG_THUMBPRINT%" goto :thumbprinterror

:movefile
	echo [+] Moving wintun.dll to %DEST_DIR%
	move /y .deps\wintun\bin\amd64\wintun.dll %DEST_DIR%\wintun.dll || goto :error
	echo [+] Moving wintun.h to %DEST_DIR%
	move /y .deps\wintun\include\wintun.h %DEST_DIR%\wintun.h || goto :error

:cleanup
	echo [+] Cleaning up temporary files
	rmdir /s /q .deps 2> NUL

:success
	echo [+] Success.
	exit /b 0

:download
	echo [+] Downloading %1 (%2)
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
