@echo off
rem Use primary code signing certificate (CN = Amagicom AB).
set SigningCertificate="%1"
set SigningCertificatePassword="%2"
set TimestampServer=http://timestamp.comodoca.com/?td=sha256
call build.bat
