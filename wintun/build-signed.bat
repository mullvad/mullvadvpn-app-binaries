@echo off
rem Use primary code signing certificate (CN = Amagicom AB).
set SigningCertificate=4104d9ceec93cdedc901192b666b3fa7e1dc8b67
set TimestampServer=http://timestamp.comodoca.com/?td=sha256
call build.bat
