# 🎬 FloatNote — DaVinci Resolve Power Companion

<p align="center">
  <img src="Sources/AppIcon.icns" width="128" height="128" alt="FloatNote Icon">
</p>

<p align="center">
  <b>Плавающее окно-компаньон для видеомонтажа в DaVinci Resolve Studio на macOS.</b><br>
  <i>The ultimate floating companion suite for DaVinci Resolve Studio & professional video editors on macOS.</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.1.0-brightgreen.svg" alt="Version 1.1.0">
  <img src="https://img.shields.io/badge/platform-macOS%2013.0+-blue.svg" alt="macOS 13.0+">
  <img src="https://img.shields.io/badge/DaVinci%20Resolve-Studio%2018%20%7C%2019%20%7C%2020%20%7C%2021-orange.svg" alt="DaVinci Resolve Studio">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License MIT">
</p>

---

[🇷🇺 Описание на русском](#-русский) | [🇬🇧 English Description](#-english)

---

## 🇷🇺 Русский

**FloatNote** — это нативное легковесное приложение на SwiftUI и AppKit, спроектированное специально для профессионального монтажа видео в DaVinci Resolve. Оно висит поверх рабочих пространств полноэкранного DaVinci Resolve (слой `1002`), моментально скрывается и открывается по горячей клавише или кнопке скрепки, и напрямую связывается с DaVinci Resolve через официальный Scripting API.

---

### ✨ Ключевые возможности

#### 1. 🎬 Глубокая интеграция с DaVinci Resolve Studio (Scripting API)
- **Живой мониторинг**: отображает подключение к активному проекту и имя текущего таймлайна (например, `🟢 Timeline 1`).
- **Интерактивные таймкоды (Click-to-Jump)**: клик по бейджу таймкода `[▶ 01:00:15:00]` в любой задаче чеклиста моментально перемещает плейхед DaVinci Resolve на этот кадр.
- **Вставка таймкода в 1 клик**: кнопка `⏱ Таймкод` в чеклисте и заметках считывает текущий кадр из DaVinci и подставляет его в текст.
- **Маркеры таймлайна**: кнопка `📍` создает маркер на таймлайне DaVinci прямо из задачи с сохранением названия и заметок.

#### 2. 🪟 Отдельные плавающие окна-компаньоны
- **⏱ Таймер монтажной смены & Помодоро (25/5)**:
  - Отдельное компактное плавающее окно.
  - Секундомер для учета общего времени работы.
  - Pomodoro-таймер (25 мин фокуса / 5 мин отдыха) со звуковыми оповещениями.
- **📋 Менеджер буфера обмена (Clipboard History)**:
  - Отдельное плавающее окно с историей скопированного текста (до 50 элементов).
  - Поиск по буферу и копирование в 1 клик для вставки в титры и текст DaVinci.

#### 3. 📐 Прозрачный оверлей безопасных зон 9:16 (Safe Areas)
- Специальная направляющая рамка формата 9:16 для монтажа вертикальных видео (Reels, TikTok, YouTube Shorts, VK Клипы).
- Подсказки зон: верхняя панель (поиск/профиль), правая колонка (лайки/шеринг), нижняя зона (титры/звук), центральный прицел.
- Режим **Lock**: оверлей становится на 100% прозрачным для кликов мыши (`click-through`), позволяя монтировать видео прямо под сеткой.

#### 4. 📸 Захват кадра в скетчер (Frame Grabber)
- Кнопка `📸` позволяет выделить кадр из вьювера DaVinci или экрана и мгновенно поместить его фоном на холст.
- Рисование стрелок, овалов, прямоугольников, прямых линий и рукописных заметок поверх кадра для раскадровки и правок. Экспорт в PNG.

#### 5. 📋 Шаблоны чеклистов (Workflow Templates)
- Встроенные пресеты для монтажеров:
  - *🎬 Предэкспортная проверка* (LUFS, оффлайн клипы, опечатки, безопасные зоны).
  - *🎨 Цветокоррекция (Color Grading)* (баланс белого, матчинг, skin tones, scopes).
  - *✂️ Черновой монтаж (Rough Cut)* (отбор дублей, A-Roll, перебивки, ритм).
- Сохранение собственного списка задач как нового шаблона в JSON.

#### 6. 🎙 Голосовой ввод (Apple Speech Framework)
- Распознавание русской речи на устройстве.
- Быстрая диктовка задач и заметок по кнопке микрофона `🎙`.

#### 7. 👻 Ghost Mode & First Mouse
- **Сквозной клик**: шапка окна и кнопки остаются интерактивными, клики по контенту пролетают прямо в таймлайн DaVinci.
- **First Mouse**: каждый элемент интерфейса реагирует с первого клика мыши даже из неактивного состояния.
- **Кнопка Pin**: клик по скрепке скрывает окно с экрана (`⇧ Space` возвращает обратно).

---

### ⌨️ Горячие клавиши (Hotkeys)

| Действие | Горячая клавиша по умолчанию | Настраивается в Настройках |
|---|---|---|
| Скрыть / Показать окно | `⇧ Space` (или клик по Pin) | Да (`⌥`, `⌘`, `⌃`, `⇧` + любая клавиша) |
| Сквозной режим (Ghost Mode) | `⌥ G` | Да |
| Открыть настройки | `⌘ ,` | — |
| Отмена в скетчере | `⌘ Z` | — |
| Закрыть приложение | `⌘ Q` | — |

---

### 🛠 Сборка из исходников (macOS)

Требования:
- macOS 13.0+ (Ventura, Sonoma, Sequoia, Tahoe)
- Xcode Command Line Tools (`xcode-select --install`)
- Python 3 (системный `/usr/bin/python3`)
- DaVinci Resolve Studio (18 / 19 / 20 / 21)

```bash
git clone https://github.com/r3yjell/FloatNote.git
cd FloatNote
chmod +x build.sh
./build.sh
```
Скрипт скомпилирует приложение в `FloatNote.app` и автоматически установит его в `/Applications/FloatNote.app`.

---

### 🪟 Планы по поддержке Windows (Roadmap)
Бизнес-логика FloatNote (скриптинг DaVinci через Python bridge, менеджер шаблонов, хранилище) абстрагирована от UI. В будущих версиях запланирован порт под Windows с отдельным графическим интерфейсом.

---

## 🇬🇧 English

**FloatNote** is a native, ultra-lightweight floating companion app crafted with SwiftUI & AppKit specifically for video editors working in DaVinci Resolve on macOS. It hovers persistently above fullscreen DaVinci Resolve Spaces (layer `1002`), hides instantly with a hotkey or pin toggle, and communicates directly with DaVinci Resolve via its official Scripting API.

### Key Features
- **DaVinci Resolve Scripting API Integration**: Live project/timeline detection, clickable timecodes `[01:00:15:00]` that jump the timeline playhead, and 1-click timeline marker creation from checklist tasks.
- **Companion Floating Windows**:
  - **Stopwatch & Pomodoro (25/5)**: Independent floating HUD window for tracking edit sessions with audio alerts.
  - **Clipboard History**: Independent window tracking copied text snippets (up to 50 items) with instant search and 1-click copy-back.
- **9:16 Safe Areas Transparent Overlay**: Aspect-ratio locked vertical video guides for Instagram Reels, TikTok, YouTube Shorts, and VK Clips with 100% click-through into DaVinci.
- **Frame Grabber into Canvas**: Snip a DaVinci viewer frame directly onto the sketch canvas to draw arrows, circles, and markup notes for colorists/editors.
- **Workflow Checklist Templates**: Built-in pre-export, color grading, and rough cut checklists + save your own custom templates to JSON.
- **Voice Dictation**: Instant speech-to-text for task and note creation powered by Apple's native Speech framework.
- **Intelligent Ghost Mode & First Mouse**: 100% click-through with interactive header controls and immediate response on the very first mouse click.

### Build from Source
```bash
git clone https://github.com/r3yjell/FloatNote.git
cd FloatNote
./build.sh
```

---

## 📄 License
Released under the [MIT License](LICENSE).
