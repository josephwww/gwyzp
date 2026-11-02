#!/usr/bin/env bash
# 把 swift build 产物组装成 .app 并打 zip 包（Apple Silicon / arm64）。
set -euo pipefail

APP_NAME="照片处理工具"
BUNDLE_ID="com.josephwww.phototool"
VERSION="1.0.0"
BIN=".build/release/PhotoTool"
ZIP="dist/PhotoTool-macOS-arm64.zip"

if [[ ! -f "$BIN" ]]; then
  echo "未找到 $BIN，请先运行: swift build -c release --arch arm64" >&2
  exit 1
fi

rm -rf "dist"
mkdir -p "dist/${APP_NAME}.app/Contents/MacOS" "dist/${APP_NAME}.app/Contents/Resources"
cp "$BIN" "dist/${APP_NAME}.app/Contents/MacOS/PhotoTool"

cat > "dist/${APP_NAME}.app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key><string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key><string>${BUNDLE_ID}</string>
  <key>CFBundleVersion</key><string>${VERSION}</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleExecutable</key><string>PhotoTool</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

# ad-hoc 签名（arm64 必须有有效签名才能运行；不等于开发者签名，见 README 的 Gatekeeper 说明）
codesign --force --sign - "dist/${APP_NAME}.app"

ditto -c -k --keepParent "dist/${APP_NAME}.app" "$ZIP"

echo "已生成 dist/${APP_NAME}.app 与 ${ZIP}"
