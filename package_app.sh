#!/bin/bash
set -e
cd "$(dirname "$0")"

PROJ="$PWD"
VERSION=$(grep 'static let marketing' "$PROJ/Sources/FinderExplorer/AppVersion.swift" | sed 's/.*"\(.*\)"/\1/')
BUILD_NUM=$(grep 'static let build' "$PROJ/Sources/FinderExplorer/AppVersion.swift" | sed 's/.*"\(.*\)"/\1/')
BUILD="$PROJ/.build/x86_64-apple-macosx/release"
APP="$PROJ/FinderExplorer-${VERSION}.app"
STAGING="$PROJ/FinderExplorer-${VERSION}.staging"

echo "=== 构建 Release ==="
swift build -c release --disable-sandbox

echo "=== 打包 .app ==="
rm -rf "$APP" "$STAGING" "$PROJ"/FinderExplorer*.app

# 先构建到无 .app 扩展名的临时目录
mkdir -p "$STAGING/Contents/MacOS"
mkdir -p "$STAGING/Contents/Resources"

cp "$BUILD/FinderExplorer" "$STAGING/Contents/MacOS/"
cp "$PROJ/AppIcon.icns" "$STAGING/Contents/Resources/"

cat > "$STAGING/Contents/Info.plist" << PLIST
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
    <string>${BUILD_NUM}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

# 重命名为 .app 触发 Launch Services 自动识别
mv "$STAGING" "$APP"

echo "=== 完成 ==="
echo "App: $APP"
echo "你可以双击打开: open $APP"
echo "或者拖入 /Applications"
