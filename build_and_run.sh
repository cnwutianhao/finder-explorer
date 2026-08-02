#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "=== Building FinderExplorer ==="
swift build --disable-sandbox

BIN=".build/x86_64-apple-macosx/debug/FinderExplorer"
echo "=== Build complete ==="
echo "Binary: $BIN"
echo "=== Launching ==="
open "$BIN"
echo "App launched!"
