#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_DIR}"

APP_NAME="MonitorSwitcher"
BUILD_DIR="${PROJECT_DIR}/.build/release"
DIST_DIR="${PROJECT_DIR}/dist"
APP_BUNDLE="${DIST_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "==> Building ${APP_NAME} in release mode..."
SWIFT_EXEC="${SCRIPT_DIR}/swiftc-wrapper.sh" swift build -c release --disable-sandbox

echo "==> Generating icon if missing..."
if [ ! -f "Resources/AppIcon.icns" ]; then
    mkdir -p Resources
    swift -module-cache-path /tmp/swift-cache "${SCRIPT_DIR}/generate_icon.swift"
fi

echo "==> Packaging ${APP_NAME}.app..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

# Copy executable
cp "${BUILD_DIR}/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

# Copy icon
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

# Write PkgInfo
echo "APPL????" > "${CONTENTS_DIR}/PkgInfo"

# Write Info.plist
cat << 'EOF' > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MonitorSwitcher</string>
    <key>CFBundleIdentifier</key>
    <string>com.lamonica.MonitorSwitcher</string>
    <key>CFBundleName</key>
    <string>Monitor Switcher</string>
    <key>CFBundleDisplayName</key>
    <string>Monitor Switcher</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>Monitor Switcher requires accessibility access to list and move windows between monitors.</string>
</dict>
</plist>
EOF

echo "==> Signing app bundle..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "==> Validating signature..."
codesign --verify --deep --strict --verbose=1 "${APP_BUNDLE}"

echo ""
echo " Successfully built and packaged ${APP_NAME}.app!"
echo "📍 Location: ${APP_BUNDLE}"
echo ""
echo "To launch the app:"
echo "  open \"${APP_BUNDLE}\""
