# 🎬 FloatNote DaVinci Resolve Plugin & Bridge

Официальный плагин-расширение для двусторонней связи между **FloatNote** и **DaVinci Resolve** (Studio & Free).

---

## ⚡ Возможности

1. **Экспорт маркеров таймлайна в чеклист FloatNote**:
   - Считывает все маркеры текущего таймлайна в DaVinci (с их цветами, именами, таймкодами и комментариями).
   - Мгновенно добавляет их в чеклист FloatNote в формате `[01:00:15:00] Задача`.
2. **Импорт задач FloatNote в маркеры DaVinci Resolve**:
   - Переносит задачи монтажа прямо на таймлайн DaVinci Resolve в виде маркеров.
3. **Управление курсором воспроизведения (Playhead Control)**:
   - Перемещение плейхеда на заданный кадр: `python3 FloatNote_Bridge.py jump 01:00:15:00`.
4. **Установка маркеров из консоли**:
   - `python3 FloatNote_Bridge.py marker 01:00:15:00 Blue "Исправить цвет" "Слишком теплый"`.

---

## 🚀 Установка

### Автоматическая установка (в один клик)
В терминале перейдите в эту папку и выполните:
```bash
./install.sh
```

### Ручная установка
Скопируйте `FloatNote_Bridge.py` в папку скриптов DaVinci Resolve:
```bash
cp FloatNote_Bridge.py "$HOME/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Utility/"
```

---

## 💻 Использование

### 1. Из интерфейса DaVinci Resolve (Studio & Free)
1. Откройте любой проект и таймлайн в DaVinci Resolve.
2. В верхнем меню выберите:
   **Workspace → Scripts → FloatNote_Bridge**
3. Плагин автоматически считает маркеры и синхронизирует их с открытым FloatNote!

### 2. Через командную строку (CLI / Автоматизация)
```bash
# Получить информацию о проекте и таймлайне:
python3 FloatNote_Bridge.py info

# Считать текущий таймкод плейхеда:
python3 FloatNote_Bridge.py get_tc

# Переместить плейхед к таймкоду:
python3 FloatNote_Bridge.py jump 01:02:30:12

# Поставить маркер на таймлайн:
python3 FloatNote_Bridge.py marker 01:02:30:12 Cyan "Правка" "Проверить звук"

# Синхронизировать маркеры таймлайна в чеклист FloatNote:
python3 FloatNote_Bridge.py sync_markers
```

---

## 📄 Лицензия
MIT License (c) 2026 r3yjell
