#!/bin/bash
set -e

APP_NAME="FloatNote"
DIR="$(cd "$(dirname "$0")" && pwd)"
APP_BUNDLE="$DIR/$APP_NAME.app"

echo "=== Сборка $APP_NAME.app ==="

# SDK selection (matches installed Swift 6.3.3)
SDK_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk"
if [ ! -d "$SDK_PATH" ]; then
    SDK_PATH="$(xcrun --show-sdk-path)"
fi

echo "Используется SDK: $SDK_PATH"

# Kill existing instance if running
pkill -x FloatNote 2>/dev/null || true

# Create App bundle structure
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy AppIcon if exists
if [ -f "$DIR/Sources/AppIcon.icns" ]; then
    cp "$DIR/Sources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# Create Info.plist
cat << 'EOF' > "$APP_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>FloatNote</string>
    <key>CFBundleIdentifier</key>
    <string>com.r3yjell.FloatNote</string>
    <key>CFBundleName</key>
    <string>FloatNote</string>
    <key>CFBundleDisplayName</key>
    <string>FloatNote</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSMicrophoneUsageDescription</key>
    <string>FloatNote использует микрофон для записи голосовых заметок монтажа.</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>FloatNote использует распознавание речи для автоматического транскрибирования голосовых заметок.</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Compile Swift sources
echo "Компиляция Swift исходников..."
swiftc -O -sdk "$SDK_PATH" \
    -target arm64-apple-macos13.0 \
    "$DIR/Sources/Storage.swift" \
    "$DIR/Sources/HotkeyManager.swift" \
    "$DIR/Sources/FloatingPanel.swift" \
    "$DIR/Sources/SettingsView.swift" \
    "$DIR/Sources/UIComponents.swift" \
    "$DIR/Sources/AudioManager.swift" \
    "$DIR/Sources/AudioNotesView.swift" \
    "$DIR/Sources/DrawingCanvasView.swift" \
    "$DIR/Sources/SafeAreasOverlay.swift" \
    "$DIR/Sources/ReferenceOverlay.swift" \
    "$DIR/Sources/NLEBridge.swift" \
    "$DIR/Sources/ChecklistTemplates.swift" \
    "$DIR/Sources/ChecklistView.swift" \
    "$DIR/Sources/NotesView.swift" \
    "$DIR/Sources/TimerWindow.swift" \
    "$DIR/Sources/ClipboardManager.swift" \
    "$DIR/Sources/SpeechManager.swift" \
    "$DIR/Sources/ContentView.swift" \
    "$DIR/Sources/AppDelegate.swift" \
    "$DIR/Sources/main.swift" \
    -o "$APP_BUNDLE/Contents/MacOS/FloatNote"

chmod +x "$APP_BUNDLE/Contents/MacOS/FloatNote"

if [ "$1" = "--install" ]; then
    echo "Установка в /Applications/$APP_NAME.app..."
    rm -rf "/Applications/$APP_NAME.app"
    cp -R "$APP_BUNDLE" "/Applications/$APP_NAME.app"
    echo "=== Установлено в: /Applications/$APP_NAME.app ==="
fi

echo "=== Сборка успешно завершена: $APP_BUNDLE ==="
