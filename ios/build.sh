#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$ROOT/ios/build"
IOS_MIN_VERSION=${IOS_MIN_VERSION:-16.0}

for command_name in go xcrun; do
    command -v "$command_name" >/dev/null 2>&1 || {
        echo "missing required command: $command_name" >&2
        exit 1
    }
done

SDKROOT=$(xcrun --sdk iphoneos --show-sdk-path)
CLANGWRAP="$(go env GOROOT)/misc/ios/clangwrap.sh"
if [[ ! -x "$CLANGWRAP" ]]; then
    echo "Go iOS clang wrapper not found: $CLANGWRAP" >&2
    exit 1
fi

mkdir -p "$OUT"

export GOOS=ios
export GOARCH=arm64
export CGO_ENABLED=1
export CC="$CLANGWRAP"
export CGO_CFLAGS="-isysroot $SDKROOT -miphoneos-version-min=$IOS_MIN_VERSION"
export CGO_LDFLAGS="-isysroot $SDKROOT -miphoneos-version-min=$IOS_MIN_VERSION -Wl,-rpath,/var/jb/usr/lib"

echo "Building 3x-ui v2.3.8 for ios/arm64"
(
    cd "$ROOT"
    go build -tags timetzdata -o "$OUT/x-ui.real" ./main.go
)

echo "Building Xray-core v1.8.16 for ios/arm64"
(
    cd "$ROOT"
    go build -o "$OUT/xray-ios-arm64.real" github.com/xtls/xray-core/main
)

echo "Building Jetsam launcher"
xcrun --sdk iphoneos clang \
    -target "arm64-apple-ios$IOS_MIN_VERSION" \
    -isysroot "$SDKROOT" \
    -Os \
    -Wl,-rpath,/var/jb/usr/lib \
    -o "$OUT/xui-jetsam-launcher" \
    "$ROOT/ios/launcher.c"

echo "Build output: $OUT"
