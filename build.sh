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

# Copy AppIcon and NLE Bridge Scripts
if [ -f "$DIR/Sources/AppIcon.icns" ]; then
    cp "$DIR/Sources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

if [ -f "$DIR/Plugins/DaVinciResolve/FloatNote_Bridge.py" ]; then
    cp "$DIR/Plugins/DaVinciResolve/FloatNote_Bridge.py" "$APP_BUNDLE/Contents/Resources/FloatNote_Bridge.py"
fi

if [ -f "$DIR/Plugins/PremierePro/FloatNote_Premiere.jsx" ]; then
    cp "$DIR/Plugins/PremierePro/FloatNote_Premiere.jsx" "$APP_BUNDLE/Contents/Resources/FloatNote_Premiere.jsx"
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
    <string>1.3</string>
    <key>CFBundleVersion</key>
    <string>5</string>
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

# Code sign with ad-hoc signature to avoid malformed bundle errors
echo "Подписание app-бандла (ad-hoc)..."
codesign --force --deep --sign - "$APP_BUNDLE"

if [ "$1" = "--install" ] || [ "$2" = "--install" ] || [ "$1" = "--all" ]; then
    echo "Установка в /Applications/$APP_NAME.app..."
    pkill -x "$APP_NAME" 2>/dev/null || true
    rm -rf "/Applications/$APP_NAME.app"
    cp -R "$APP_BUNDLE" "/Applications/$APP_NAME.app"
    xattr -cr "/Applications/$APP_NAME.app" 2>/dev/null || true
    echo "=== Установлено в: /Applications/$APP_NAME.app ==="
    
    # Обновление иконки в Dock (перезапуск кэша Dock)
    killall Dock 2>/dev/null || true
fi

if [ "$1" = "--dmg" ] || [ "$2" = "--dmg" ] || [ "$1" = "--all" ]; then
    DMG_NAME="FloatNote-1.3.dmg"
    DMG_TEMP="$DIR/dmg_staging"
    echo "=== Создание установочного DMG-образа: $DMG_NAME ==="
    rm -rf "$DMG_TEMP" "$DIR/$DMG_NAME"
    mkdir -p "$DMG_TEMP"
    
    # 1. FloatNote.app
    cp -R "$APP_BUNDLE" "$DMG_TEMP/"
    
    # 2. Symlink to Applications folder
    ln -s /Applications "$DMG_TEMP/Applications"
    
    # 3. User-friendly plugins folder
    if [ -d "$DIR/Плагины_для_видеоредакторов" ]; then
        cp -R "$DIR/Плагины_для_видеоредакторов" "$DMG_TEMP/"
    fi
    
    # 4. Quick 1-click fix script directly in root of DMG
    if [ -f "$DIR/Плагины_для_видеоредакторов/Снять_карантин_macOS.command" ]; then
        cp "$DIR/Плагины_для_видеоредакторов/Снять_карантин_macOS.command" "$DMG_TEMP/🩺 Если_пишет_повреждено.command"
        chmod +x "$DMG_TEMP/🩺 Если_пишет_повреждено.command"
    fi
    
    # 5. Readme text for users
    cat << 'EOF' > "$DMG_TEMP/КАК_УСТАНОВИТЬ.txt"
🎬 FloatNote — Установка на macOS:

1. Перетащите FloatNote.app в папку Applications (Программы).
2. Запустите FloatNote.
3. Откройте папку «Плагины_для_видеоредакторов» и дважды кликните «Установить_плагины_в_1_клик.command» 
   (или нажмите «Установить плагины NLE» внутри настроек самого FloatNote).

💡 Если macOS пишет «Приложение повреждено»:
   Дважды кликните по файлу «🩺 Если_пишет_повреждено.command» прямо в этом окне!
   Либо: нажмите правой кнопкой мыши по FloatNote.app в Программах -> выберите «Открыть» -> «Открыть».
EOF
    
    hdiutil create -volname "FloatNote" -srcfolder "$DMG_TEMP" -ov -format UDZO "$DIR/$DMG_NAME"
    rm -rf "$DMG_TEMP"
    echo "=== DMG успешно создан: $DIR/$DMG_NAME ==="
fi

echo "=== Сборка успешно завершена: $APP_BUNDLE ==="
