#!/bin/bash
set -e

APP_NAME="Up!"
EXECUTABLE_NAME="Up"
MARKETING_VERSION="${MARKETING_VERSION:-1.0.0}"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "Building $APP_NAME..."

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS" "$RESOURCES"

# Generate app icon
echo "Generating app icon..."
swift generate_icon.swift
iconutil -c icns -o "$RESOURCES/AppIcon.icns" "$BUILD_DIR/AppIcon.iconset"
rm -rf "$BUILD_DIR/AppIcon.iconset"

# Compile
echo "Compiling..."
swiftc \
    -o "$MACOS/$EXECUTABLE_NAME" \
    -framework Cocoa \
    -framework IOKit \
    -framework ServiceManagement \
    -swift-version 5 \
    -Osize \
    Up/main.swift

# Create Info.plist
cat > "$CONTENTS/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$EXECUTABLE_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.up.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$MARKETING_VERSION</string>
    <key>CFBundleVersion</key>
    <string>$MARKETING_VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
</dict>
</plist>
PLIST

# Create PkgInfo
echo -n "APPL????" > "$CONTENTS/PkgInfo"

echo ""
echo "Build complete: $APP_BUNDLE"
echo ""
echo "To install, run:"
echo "  cp -R \"$APP_BUNDLE\" ~/Applications/"
echo ""
echo "To run directly:"
echo "  open \"$APP_BUNDLE\""
