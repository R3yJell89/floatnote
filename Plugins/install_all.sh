#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "======================================================"
echo "🎬 FloatNote — Автоматическая установка плагинов NLE"
echo "======================================================"

# 1. DaVinci Resolve
DAVINCI_DIR="$HOME/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Utility"
echo ""
echo "🔍 [1/2] Проверка DaVinci Resolve..."
if [ -d "$HOME/Library/Application Support/Blackmagic Design/DaVinci Resolve" ]; then
    mkdir -p "$DAVINCI_DIR"
    cp -f "$DIR/DaVinciResolve/FloatNote_Bridge.py" "$DAVINCI_DIR/FloatNote_Bridge.py"
    chmod +x "$DAVINCI_DIR/FloatNote_Bridge.py"
    echo "   ✅ DaVinci Resolve плагин установлен!"
    echo "      Путь: $DAVINCI_DIR/FloatNote_Bridge.py"
    echo "      Запуск в DaVinci: Workspace -> Scripts -> Utility -> FloatNote_Bridge"
else
    echo "   ⚠️ DaVinci Resolve не найден в системе (пропуск)."
fi

# 2. Adobe Premiere Pro
echo ""
echo "🔍 [2/2] Настройка Adobe Premiere Pro..."
PREMIERE_SCRIPTS="$HOME/Documents/Adobe/Premiere Pro/Scripts"
mkdir -p "$PREMIERE_SCRIPTS"
cp -f "$DIR/PremierePro/FloatNote_Premiere.jsx" "$PREMIERE_SCRIPTS/FloatNote_Premiere.jsx"
echo "   ✅ Скрипт для Adobe Premiere Pro установлен!"
echo "      Путь: $PREMIERE_SCRIPTS/FloatNote_Premiere.jsx"
echo "      Запуск: File -> Scripts -> FloatNote_Premiere.jsx (или через ExtendScript Toolkit)"

echo ""
echo "======================================================"
echo "🎉 Готово! Все доступные NLE подвязаны к FloatNote."
echo "======================================================"
