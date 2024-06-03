@echo off
setlocal

set SIG_THUMBPRINT=DF98E075A012ED8C86FBCF14854B8F9555CB3D45

:getwintun
	rmdir /s /q .deps 2> NUL
	mkdir .deps || goto :error
	cd .deps || goto :error
	call :download wintun.zip https://www.wintun.net/builds/wintun-0.14.1.zip 07c256185d6ee3652e09fa55c0b673e2624b565e02c4b9091c79ca7d2f24ef51 || goto :error
	echo [+] Extracting wintun.dll
	tar -xf wintun.zip || goto :error
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
	set DEST_DIR=%~dp0..\%1-pc-windows-msvc\wintun
	set ARCH=%2
	echo [+] Verifying wintun.dll signature
	signtool verify /v /pa .deps\wintun\bin\%ARCH%\wintun.dll || goto :error
	powershell -command "if ((Get-AuthenticodeSignature -FilePath .deps\wintun\bin\${env:ARCH}\wintun.dll).SignerCertificate.Thumbprint -ne $env:SIG_THUMBPRINT) { exit 1 }" || goto :thumbprinterror

	mkdir %DEST_DIR%
	echo [+] Moving wintun.dll to %DEST_DIR%
	move /y .deps\wintun\bin\%ARCH%\wintun.dll %DEST_DIR%\wintun.dll || goto :error
	echo [+] Moving wintun.h to %DEST_DIR%
	copy /y .deps\wintun\include\wintun.h %DEST_DIR%\wintun.h || goto :error
	goto :eof

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
