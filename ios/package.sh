#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD="$ROOT/ios/build"
STAGE="$BUILD/package-root"
VERSION=2.3.8
PACKAGE_REVISION=${PACKAGE_REVISION:-1}
PACKAGE_VERSION="${VERSION}-ios${PACKAGE_REVISION}"
PACKAGE_NAME=com.xboxpig.3x-ui
OUTPUT="$BUILD/${PACKAGE_NAME}_${PACKAGE_VERSION}_iphoneos-arm64.deb"

command -v dpkg-deb >/dev/null 2>&1 || {
    echo "missing required command: dpkg-deb" >&2
    exit 1
}

for required_file in \
    "$BUILD/x-ui.real" \
    "$BUILD/xray-ios-arm64.real" \
    "$BUILD/xui-jetsam-launcher" \
    "$ROOT/ios/assets/geoip.dat" \
    "$ROOT/ios/assets/geosite.dat"; do
    if [[ ! -f "$required_file" ]]; then
        echo "missing build input: $required_file" >&2
        exit 1
    fi
done

case "$STAGE" in
    "$ROOT"/ios/build/package-root) rm -rf "$STAGE" ;;
    *) echo "refusing unsafe staging path: $STAGE" >&2; exit 1 ;;
esac

mkdir -p \
    "$STAGE/DEBIAN" \
    "$STAGE/var/jb/Library/LaunchDaemons" \
    "$STAGE/var/jb/etc/profile.d" \
    "$STAGE/var/jb/usr/bin" \
    "$STAGE/var/jb/usr/local/x-ui/bin"

cp "$ROOT/ios/layout/DEBIAN/control" "$STAGE/DEBIAN/control"
sed -i.bak "s/@PACKAGE_VERSION@/$PACKAGE_VERSION/g" "$STAGE/DEBIAN/control"
rm -f "$STAGE/DEBIAN/control.bak"
cp "$ROOT/ios/layout/DEBIAN/postinst" "$STAGE/DEBIAN/postinst"
cp "$ROOT/ios/layout/DEBIAN/prerm" "$STAGE/DEBIAN/prerm"
cp "$ROOT/ios/layout/DEBIAN/postrm" "$STAGE/DEBIAN/postrm"
chmod 0755 "$STAGE/DEBIAN/postinst" "$STAGE/DEBIAN/prerm" "$STAGE/DEBIAN/postrm"

cp "$ROOT/ios/layout/com.xboxpig.3x-ui.plist" \
    "$STAGE/var/jb/Library/LaunchDaemons/com.xboxpig.3x-ui.plist"
cp "$ROOT/ios/layout/x-ui-profile.sh" "$STAGE/var/jb/etc/profile.d/x-ui.sh"
cp "$ROOT/x-ui.sh" "$STAGE/var/jb/usr/local/x-ui/x-ui.sh"
cp "$BUILD/x-ui.real" "$STAGE/var/jb/usr/local/x-ui/x-ui.real"
cp "$BUILD/xui-jetsam-launcher" "$STAGE/var/jb/usr/local/x-ui/x-ui"
cp "$BUILD/xray-ios-arm64.real" \
    "$STAGE/var/jb/usr/local/x-ui/bin/xray-ios-arm64.real"
cp "$BUILD/xui-jetsam-launcher" \
    "$STAGE/var/jb/usr/local/x-ui/bin/xray-ios-arm64"
cp "$ROOT/ios/assets/geoip.dat" "$STAGE/var/jb/usr/local/x-ui/bin/geoip.dat"
cp "$ROOT/ios/assets/geosite.dat" "$STAGE/var/jb/usr/local/x-ui/bin/geosite.dat"

chmod 0755 \
    "$STAGE/var/jb/usr/local/x-ui/x-ui.sh" \
    "$STAGE/var/jb/usr/local/x-ui/x-ui.real" \
    "$STAGE/var/jb/usr/local/x-ui/x-ui" \
    "$STAGE/var/jb/usr/local/x-ui/bin/xray-ios-arm64.real" \
    "$STAGE/var/jb/usr/local/x-ui/bin/xray-ios-arm64"
ln -s /var/jb/usr/local/x-ui/x-ui.sh "$STAGE/var/jb/usr/bin/x-ui"

dpkg-deb --build --root-owner-group "$STAGE" "$OUTPUT"
echo "Package written to $OUTPUT"
