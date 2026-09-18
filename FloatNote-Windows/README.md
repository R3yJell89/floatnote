# 🎬 FloatNote for Windows (PowerToys Style Edition)

**The Lightweight Native Floating Companion Suite for Video Editors on Windows 11 / 10.**

---

## ✨ Features

- **Designed in Microsoft PowerToys Style**:
  - Immersive Dark Theme with translucent **Mica and Acrylic Blur** via Win32 Desktop Window Manager.
  - Native Windows 11 rounded corners and Segoe UI Variable typography.
- **Ultra-Lightweight (~30-35 MB RAM)**:
  - Built with pure C# and .NET 8 WPF. Zero Electron overhead, zero CPU usage when idle.
  - Portable single-file executable (`FloatNote.exe`).
- **NLE Integrations**:
  - **DaVinci Resolve**: Auto reverse-marker sync on timeline creation, live timecode reading, and click-to-jump navigation.
  - **Adobe Premiere Pro**: Sequence focus and marker timecode handoff.
- **Full Suite of Video Editor HUD Tools**:
  - 📋 **Checklist**: Uncluttered minimal task list with discreet timecode badges.
  - 📝 **Notes**: Quick editor/director notes with autosave.
  - ⏱ **Stopwatch & Pomodoro (25/5)**: Independent floating timer HUD.
  - 📋 **Clipboard Manager**: Floating history of copied titles and strings.
  - 📐 **Safe Areas HUD**: Fullscreen transparent 9:16 and 16:9 guidelines with mouse click-through locking.

---

## 🚀 Build Instructions

### Requirements
- Windows 10 (Build 19041+) or Windows 11
- [.NET 8.0 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)

### Build Single-File Executable
```cmd
dotnet publish FloatNote.csproj -c Release -r win-x64 --self-contained false -p:PublishSingleFile=true -p:EnableCompressionInSingleFile=true -o ./publish
```
The output executable will be created at `./publish/FloatNote.exe`.
