#!/bin/bash
# Builds VedicAstro.app — a clickable macOS application
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="VedicAstro"
APP_DIR="$PROJECT_DIR/.build/${APP_NAME}.app"
INSTALL_DIR="$HOME/Applications"

echo "Building VedicAstro..."
cd "$PROJECT_DIR"
swift build --product VedicAstroApp -c release 2>&1 | tail -3

echo "Assembling app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp ".build/arm64-apple-macosx/release/VedicAstroApp" "$APP_DIR/Contents/MacOS/$APP_NAME"

# Info.plist
cat > "$APP_DIR/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>VedicAstro</string>
    <key>CFBundleIdentifier</key>
    <string>com.vedicastro.app</string>
    <key>CFBundleName</key>
    <string>VedicAstro</string>
    <key>CFBundleDisplayName</key>
    <string>VedicAstro</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.5</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

# Install to ~/Applications
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/${APP_NAME}.app"
cp -R "$APP_DIR" "$INSTALL_DIR/"

echo ""
echo "Done! VedicAstro.app installed to: $INSTALL_DIR/${APP_NAME}.app"
echo "You can find it in Launchpad or Spotlight — search 'VedicAstro'"
echo ""
echo "To open now:"
echo "  open $INSTALL_DIR/${APP_NAME}.app"
