#!/bin/bash
set -e
cd "$(dirname "$0")"

PROJ="$PWD"
VERSION=$(grep 'static let marketing' "$PROJ/Sources/FinderExplorer/AppVersion.swift" | sed 's/.*"\(.*\)"/\1/')
BUILD_NUM=$(grep 'static let build' "$PROJ/Sources/FinderExplorer/AppVersion.swift" | sed 's/.*"\(.*\)"/\1/')

build_arch () {
    local ARCH=$1
    local SUFFIX=$2
    local BUILD_DIR=".build/${ARCH}-apple-macosx/release"
    local APP="FinderExplorer_${VERSION}-${SUFFIX}.app"
    local STAGING="FinderExplorer_${VERSION}-${SUFFIX}.staging"

    echo "=== 打包 ${SUFFIX} ==="
    rm -rf "$APP" "$STAGING"
    mkdir -p "$STAGING/Contents/MacOS"
    mkdir -p "$STAGING/Contents/Resources"

    cp "$BUILD_DIR/FinderExplorer" "$STAGING/Contents/MacOS/"
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

    mv "$STAGING" "$APP"
    echo "  → $APP"
    file "$APP/Contents/MacOS/FinderExplorer"
}

build_universal () {
    local BUILD_DIR=".build/apple/Products/Release"
    local APP="FinderExplorer_${VERSION}-universal.app"
    local STAGING="FinderExplorer_${VERSION}-universal.staging"

    echo "=== 打包 Universal ==="
    rm -rf "$APP" "$STAGING"
    mkdir -p "$STAGING/Contents/MacOS"
    mkdir -p "$STAGING/Contents/Resources"

    cp "$BUILD_DIR/FinderExplorer" "$STAGING/Contents/MacOS/"
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

    mv "$STAGING" "$APP"
    echo "  → $APP"
    file "$APP/Contents/MacOS/FinderExplorer"
}

# 清理旧产物
rm -rf "$PROJ"/FinderExplorer*.app "$PROJ"/FinderExplorer*.staging

echo "=== 构建 x86_64 ==="
swift build -c release --disable-sandbox --arch x86_64

echo "=== 构建 arm64 ==="
swift build -c release --disable-sandbox --arch arm64

echo "=== 构建 Universal ==="
swift build -c release --disable-sandbox --arch arm64 --arch x86_64

echo ""
build_arch x86_64  "amd64"
echo ""
build_arch arm64   "arm64"
echo ""
build_universal
echo ""
echo "=== 全部完成 ==="
echo "Intel:  $PROJ/FinderExplorer_${VERSION}-amd64.app"
echo "ARM:    $PROJ/FinderExplorer_${VERSION}-arm64.app"
echo "通用:   $PROJ/FinderExplorer_${VERSION}-universal.app"
