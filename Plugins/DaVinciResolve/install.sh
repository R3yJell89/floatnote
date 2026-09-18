#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$HOME/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Utility"

echo "=== Установка плагина FloatNote для DaVinci Resolve ==="

mkdir -p "$TARGET_DIR"

cp "$DIR/FloatNote_Bridge.py" "$TARGET_DIR/FloatNote_Bridge.py"
chmod +x "$TARGET_DIR/FloatNote_Bridge.py"

echo "✅ Плагин успешно установлен в:"
echo "   $TARGET_DIR/FloatNote_Bridge.py"
echo ""
echo "📌 Теперь в DaVinci Resolve откройте верхнее меню:"
echo "   Workspace -> Scripts -> FloatNote_Bridge"
