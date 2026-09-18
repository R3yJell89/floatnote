# 🎬 FloatNote — The Pro Video Editor Floating Companion

<p align="center">
  <img src="Sources/AppIcon.icns" width="128" height="128" alt="FloatNote Icon">
</p>

<p align="center">
  <b>Универсальное плавающее окно-компаньон для видеомонтажеров на macOS.</b><br>
  <i>The ultimate native floating companion suite for video editors & creators on macOS.</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.1.0-brightgreen.svg" alt="Version 1.1.0">
  <img src="https://img.shields.io/badge/platform-macOS%2013.0+-blue.svg" alt="macOS 13.0+">
  <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift 6">
  <img src="https://img.shields.io/badge/DaVinci%20Resolve-Companion%20Plugin-ff69b4.svg" alt="DaVinci Plugin">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License MIT">
</p>

---

[🇷🇺 Описание на русском](#-русский) | [🇬🇧 English Description](#-english)

---

## 📸 Скриншоты / Screenshots

<p align="center">
  <img src="docs/screenshots/01_checklist_view.png" width="300" alt="Чеклист монтажа">&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/screenshots/02_notes_view.png" width="300" alt="Заметки и сценарий">
</p>
<p align="center">
  <img src="docs/screenshots/03_audio_notes.png" width="300" alt="Голосовые заметки">&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/screenshots/04_sketch_view.png" width="300" alt="Скетчер поверх кадра">
</p>
<p align="center">
  <img src="docs/screenshots/05_timer_window.png" width="280" alt="Таймер монтажа">&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/screenshots/06_clipboard_window.png" width="280" alt="Менеджер буфера обмена">
</p>
<p align="center">
  <img src="docs/screenshots/07_safe_areas_overlay.png" width="360" alt="Безопасные зоны 9:16">&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/screenshots/08_settings_view.png" width="300" alt="Окно настроек">
</p>

---

## 🇷🇺 Русский

**FloatNote** — нативное, сверхлегкое приложение на SwiftUI и AppKit, созданное специально для видеомонтажеров. Оно плавает поверх любых полноэкранных NLE (DaVinci Resolve, Adobe Premiere Pro, Final Cut Pro, CapCut, Avid), не перехватывает фокус у таймлайна, мгновенно скрывается по горячей клавише и объединяет все вспомогательные инструменты монтажера в один клик.

В ядре приложения нет жестких привязок — FloatNote работает с любой монтажкой. Для пользователей **DaVinci Resolve Studio & Free** в комплекте идет официальный companion-плагин в папке `Plugins/DaVinciResolve/`.

---

### ✨ Ключевые возможности

#### 1. 🪟 Полноэкранный плавающий HUD (Level 1002)
- Висит поверх полноэкранных пространств Spaces без переключения рабочего стола (`.nonactivatingPanel`, `canJoinAllSpaces`, `fullScreenAuxiliary`).
- **First Mouse**: каждый элемент управления реагирует мгновенно с первого же клика мыши.
- **Интерактивный Pin**: скрепка для мгновенного скрытия окна (`⇧ Space` возвращает обратно).
- **Ghost Mode (`⌥ G`)**: сквозной клик сквозь окно прямо в таймлайн или плеер.

#### 2. 📋 Умный чеклист и таймкоды
- Распознавание таймкодов формата `HH:MM:SS:FF`: кликабельные бейджи `[00:01:24:00]` мгновенно копируют таймкод в буфер обмена для вставки в монтажку.
- Кнопка `⏱ Таймкод` вставляет таймкод прямо из буфера или по шаблону.
- Шаблоны монтажных задач:
  - *🎬 Предэкспортная проверка* (LUFS, offline media, титры, safe zones).
  - *🎨 Цветокоррекция* (баланс белого, skin tones, scopes).
  - *✂️ Черновой монтаж* (A-roll, отбор дублей, ритм).
  - Сохранение собственных шаблонов в JSON.

#### 3. 📝 Заметки монтажера и сценарий
- Быстрые заметки, правки от режиссера или сценарий с автосохранением в реальном времени.
- Встроенная диктовка голосом (`🎙`) на базе Apple Speech Framework (офлайн-распознавание русской и английской речи).

#### 4. ⏱ Отдельное окно: Таймер монтажной смены & Помодоро
- Независимое плавающее окно:
  - **Секундомер**: учет рабочего времени над проектом.
  - **Pomodoro 25/5**: интервалы глубокого фокуса (25 мин работы / 5 мин отдыха) со звуковыми уведомлениями.

#### 5. 📋 Отдельное окно: Менеджер буфера обмена (Clipboard History)
- Независимое плавающее окно истории скопированных текстов (до 50 записей).
- Мгновенный возврат любого фрагмента в буфер для быстрой вставки в титры, генераторы текста или заметки.

#### 6. 📐 Прозрачный оверлей безопасных зон 9:16 (Safe Areas)
- Направляющая сетка для вертикальных форматов: Instagram Reels, TikTok, YouTube Shorts, VK Клипы.
- Разметка зон интерфейса (верхняя шапка, правая колонка кнопок, нижнее описание) и центральный прицел.
- Кнопка **Lock**: оверлей блокируется и становится на 100% прозрачным для кликов мыши, позволяя монтировать видео прямо под направляющими.

#### 7. 📸 Захват кадра и скетчер (Frame Grabber & Sketch)
- Захват стоп-кадра из вьювера монтажки (`📸`) в качестве фона на холст.
- Инструменты аннотирования: стрелки, прямоугольники, круги, линии, карандаш, палитра цветов, толщина кисти.
- Экспорт эскизов с правками в PNG для отправки заказчику.

---

### 🔌 Интеграция с DaVinci Resolve & Adobe Premiere Pro

FloatNote поддерживает мгновенную синхронизацию маркеров таймлайна и управление воспроизведением для **DaVinci Resolve** и **Adobe Premiere Pro**.

#### ⚡ Автоматическая установка плагинов в 1 команду

В терминале выполни:
```bash
./Plugins/install_all.sh
```
Скрипт автоматически найдет установленные в системе видеоредакторы и проставит нужные модули расширения:
- **DaVinci Resolve**: устанавливает `FloatNote_Bridge.py` в системную папку Fusion Scripts.
- **Adobe Premiere Pro**: устанавливает `FloatNote_Premiere.jsx` в скрипты Premiere.

---

#### 🎬 Использование в DaVinci Resolve (Studio & Free)
1. В верхнем меню DaVinci выбери: **Workspace → Scripts → Utility → FloatNote_Bridge**.
2. Все маркеры текущего таймлайна с их названиями, комментариями и точными таймкодами мгновенно появятся в чеклисте FloatNote на лету!
3. **Авто-переход к кадру**: при клике на бейдж таймкода `[01:00:15:00]` в чеклисте FloatNote плейхед в DaVinci **автоматически прыгает на этот кадр** (и одновременно копирует таймкод в буфер обмена).

#### 🎞 Использование в Adobe Premiere Pro
1. В Premiere Pro открой таймлайн с маркерами.
2. Запусти: **File → Scripts → FloatNote_Premiere.jsx** (или через ExtendScript Toolkit).
3. Маркеры синхронизируются в `checklist.json` и сразу отобразятся в открытом окне FloatNote.

#### CLI-режим (дополнительно)

```bash
# Информация о проекте и таймлайне
python3 FloatNote_Bridge.py info

# Текущий таймкод плейхеда
python3 FloatNote_Bridge.py get_tc

# Переместить плейхед к таймкоду
python3 FloatNote_Bridge.py jump 01:02:30:12

# Поставить маркер на таймлайн
python3 FloatNote_Bridge.py marker 01:02:30:12 Cyan "Правка" "Проверить звук"

# Синхронизировать маркеры таймлайна → чеклист FloatNote
python3 FloatNote_Bridge.py sync_markers
```

Подробнее — см. [`Plugins/DaVinciResolve/README.md`](Plugins/DaVinciResolve/README.md).

---

### ⌨️ Горячие клавиши по умолчанию

| Действие | Хоткей | Настройка |
|---|---|---|
| Скрыть / Показать окно | `⇧ Space` | Настраивается в Настройках (`⌘ ,`) |
| Сквозной режим (Ghost Mode) | `⌥ G` | Настраивается в Настройках |
| Открыть Настройки | `⌘ ,` | В окне приложения |
| Отмена действия в скетчере | `⌘ Z` | Вкладка «Скетч» |

---

### 🛠 Сборка и установка

**Требования:**
- macOS 13.0+ (Ventura, Sonoma, Sequoia, Tahoe)
- Apple Silicon (M1/M2/M3/M4) или Intel Mac
- Xcode Command Line Tools (`xcode-select --install`)

```bash
git clone https://github.com/r3yjell/FloatNote.git
cd FloatNote
chmod +x build.sh
./build.sh --install
```

Приложение соберется и установится в папку `/Applications/FloatNote.app`.

---

## 🇬🇧 English

**FloatNote** is a native, ultra-lightweight floating companion app crafted with SwiftUI & AppKit for professional video editors. It floats above fullscreen NLE windows (DaVinci Resolve, Adobe Premiere Pro, Final Cut Pro, CapCut, Avid), avoids stealing focus from your timeline, hides instantly with a hotkey, and bundles all essential editing companion tools into one click.

### ✨ Features
- **Fullscreen Floating HUD**: Layer `1002`, `.nonactivatingPanel`, First Mouse responsiveness.
- **Interactive Checklists & Timecodes**: Automatic `HH:MM:SS:FF` detection with click-to-copy timecode badges.
- **Workflow Templates**: Built-in checklists for Color Grading, Pre-export checks, and Rough Cut review.
- **Standalone Companion Windows**:
  - **Timer & Pomodoro**: Stopwatch and 25/5 focus timer.
  - **Clipboard History**: Up to 50 copied text snippets with 1-click restore.
- **Transparent 9:16 Safe Areas Overlay**: Lockable click-through grid for TikTok, Reels & Shorts.
- **Frame Grabber & Sketch**: Grab viewer frames and annotate them with arrows, shapes, and text notes.
- **Voice Dictation**: Speech-to-text dictation via Apple Speech Framework.
- **DaVinci Resolve Plugin**: Dedicated companion bridge script in `Plugins/DaVinciResolve/` for timeline synchronization and marker placement.

---

### 📄 Лицензия / License

MIT License. Свободно для личного и коммерческого использования.
Разработано с заботой о видеомонтажерах.
*(P.S. добавили больше багов, чтобы можно было исправить 😉)*
