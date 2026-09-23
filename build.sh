#!/bin/bash
# 构建 鹈鹕监工.app：合成音效 -> swiftc 编译 -> 组装 bundle -> ad-hoc 签名
set -euo pipefail
cd "$(dirname "$0")"

APP=build/PelicanNanny.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

python3 make_sounds.py "$APP/Contents/Resources"

swiftc -O \
  -module-cache-path .build/ModuleCache \
  -o "$APP/Contents/MacOS/PelicanNanny" \
  Sources/*.swift \
  -framework AppKit -framework SwiftUI -framework AVFoundation

cp Info.plist "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"
codesign --force -s - "$APP"

echo "build OK -> $APP"
