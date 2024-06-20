@echo off
setlocal

set SIG_THUMBPRINT=DF98E075A012ED8C86FBCF14854B8F9555CB3D45

:getwgnt
	rmdir /s /q .deps 2> NUL
	mkdir .deps || goto :error
	cd .deps || goto :error
	call :download wireguard-nt.zip https://download.wireguard.com/wireguard-nt/wireguard-nt-0.4.zip || goto :error
	echo [+] Extracting wireguard.dll
	tar -xf wireguard-nt.zip || goto :error
	cd .. || goto :error

	call :verify_and_copy x86_64 amd64 || goto :error
	call :verify_and_copy aarch64 arm64 || goto :error

:cleanup
	echo [+] Cleaning up temporary files
	rmdir /s /q .deps 2> NUL

:success
	echo [+] Success.
	exit /b 0

:verify_and_copy
	set DEST_DIR=%~dp0..\%1-pc-windows-msvc\wireguard-nt
	set ARCH=%2
	echo [+] Verifying wireguard.dll signature
	signtool verify /v /pa .deps\wireguard-nt\bin\%ARCH%\wireguard.dll || goto :error
	powershell -command "if ((Get-AuthenticodeSignature -FilePath .deps\wireguard-nt\bin\${env:ARCH}\wireguard.dll).SignerCertificate.Thumbprint -ne $env:SIG_THUMBPRINT) { exit 1 }" || goto :thumbprinterror

	mkdir %DEST_DIR%
	echo [+] Moving wireguard.dll to %DEST_DIR%
	move /y .deps\wireguard-nt\bin\%ARCH%\wireguard.dll %DEST_DIR%\wireguard.dll || goto :error
	echo [+] Moving wireguard.h to %DEST_DIR%
	copy /y .deps\wireguard-nt\include\wireguard.h %DEST_DIR%\wireguard.h || goto :error
	goto :eof

:download
	echo [+] Downloading %1 (%2)
	curl -#fLo %1 %2 || exit /b 1
	goto :eof

:thumbprinterror
	echo [-] Failed: Unexpected signature
	exit /b 1

:error
	echo [-] Failed with error #%errorlevel%.
	cmd /c exit %errorlevel%
