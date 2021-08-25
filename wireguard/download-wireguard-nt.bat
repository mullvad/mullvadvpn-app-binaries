@echo off
setlocal

set SIG_THUMBPRINT=DF98E075A012ED8C86FBCF14854B8F9555CB3D45
set DEST_DIR=%~dp0%..\x86_64-pc-windows-msvc\wireguard-nt

:getwgnt
	rmdir /s /q .deps 2> NUL
	mkdir .deps || goto :error
	cd .deps || goto :error
	call :download wireguard-nt.zip https://download.wireguard.com/wireguard-nt/wireguard-nt-0.4.zip || goto :error
	echo [+] Extracting wireguard.dll
	tar -xf wireguard-nt.zip || goto :error
	cd .. || goto :error

:verify
	echo [+] Verifying wireguard.dll signature
	signtool verify /v /pa .deps\wireguard-nt\bin\amd64\wireguard.dll || goto :error
	for /f %%a in ('powershell -command "(Get-AuthenticodeSignature -FilePath .deps\wireguard-nt\bin\amd64\wireguard.dll).SignerCertificate.Thumbprint"') ^
do if not "%%a"=="%SIG_THUMBPRINT%" goto :thumbprinterror

:movefile
	echo [+] Moving wireguard.dll to %DEST_DIR%
	move /y .deps\wireguard-nt\bin\amd64\wireguard.dll %DEST_DIR%\wireguard.dll || goto :error
	echo [+] Moving wireguard.h to %DEST_DIR%
	move /y .deps\wireguard-nt\include\wireguard.h %DEST_DIR%\wireguard.h || goto :error

:cleanup
	echo [+] Cleaning up temporary files
	rmdir /s /q .deps 2> NUL

:success
	echo [+] Success.
	exit /b 0

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
