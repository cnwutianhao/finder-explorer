#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "=== Building FinderExplorer (Universal) ==="
swift build --disable-sandbox --arch arm64 --arch x86_64

BIN=".build/apple/Products/Release/FinderExplorer"
echo "=== Build complete ==="
echo "Binary: $BIN"
echo "=== Launching ==="
open "$BIN"
echo "App launched!"
