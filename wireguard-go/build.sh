set -eu

case "$(uname -s)" in
    Linux*)     PLATFORM="linux";;
    Darwin*)    PLATFORM="macos";;
    MINGW*)     PLATFORM="windows";;
esac

rm wireguard-go/donotuseon_linux.go 2>&1 >/dev/null || true
cp libwg.go wireguard-go/

pushd wireguard-go
  go build -v -o libwg.a -buildmode c-archive
popd

cp wireguard-go/libwg.a ../$PLATFORM/libwg.a
