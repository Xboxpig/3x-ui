#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ASSETS="$ROOT/ios/assets"
GEOIP_URL=${GEOIP_URL:-https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat}
GEOSITE_URL=${GEOSITE_URL:-https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat}

command -v curl >/dev/null 2>&1 || {
    echo "missing required command: curl" >&2
    exit 1
}

mkdir -p "$ASSETS"
curl -fL --retry 3 -o "$ASSETS/geoip.dat" "$GEOIP_URL"
curl -fL --retry 3 -o "$ASSETS/geosite.dat" "$GEOSITE_URL"

echo "Assets written to $ASSETS"
