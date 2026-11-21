#!/bin/sh
set -eu
cd "$(dirname "$0")"
swift build -c release
app=dist/F19Layer.app
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
iconset=.build/F19Layer.iconset
mkdir -p "$iconset"
sips -s format png Assets/F19Layer.svg --out "$iconset/icon_512x512@2x.png" >/dev/null
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$iconset/icon_512x512@2x.png" --out "$iconset/icon_${size}x${size}.png" >/dev/null
  if [ "$size" -lt 512 ]; then
    pixels=$((size * 2))
    sips -z "$pixels" "$pixels" "$iconset/icon_512x512@2x.png" --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
  fi
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/F19Layer.icns"
cp NOTICE "$app/Contents/Resources/"
cp "$(swift build -c release --show-bin-path)/F19Layer" "$app/Contents/MacOS/"
cp Info.plist "$app/Contents/"
identity=${SIGN_IDENTITY:-}
if [ -z "$identity" ]; then
  if security find-certificate -c 'F19Layer Local Signing' >/dev/null 2>&1; then
    identity='F19Layer Local Signing'
  else
    identity=-
  fi
fi
codesign --force --sign "$identity" "$app"
codesign --verify --strict "$app"
