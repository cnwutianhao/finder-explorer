#!/bin/bash
set -e
cd "$(dirname "$0")"

PROJ="$PWD"
BUILD="$PROJ/.build/x86_64-apple-macosx/release"
APP="$PROJ/FinderExplorer.app"

echo "=== 构建 Release ==="
swift build -c release --disable-sandbox

echo "=== 打包 .app ==="
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp "$BUILD/FinderExplorer" "$APP/Contents/MacOS/"
cp "$PROJ/AppIcon.icns" "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>FinderExplorer</string>
    <key>CFBundleIdentifier</key>
    <string>com.finderexplorer.app</string>
    <key>CFBundleName</key>
    <string>FinderExplorer</string>
    <key>CFBundleDisplayName</key>
    <string>FinderExplorer</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "=== 完成 ==="
echo "App: $APP"
echo "你可以双击打开: open $APP"
echo "或者拖入 /Applications"
