import SwiftUI
import AppKit

// MARK: - Main Content View

struct ContentView: View {
    @ObservedObject var storage = StorageManager.shared
    @ObservedObject var timerPanel = TimerPanelManager.shared
    @ObservedObject var clipboardPanel = ClipboardPanelManager.shared
    @ObservedObject var safeAreas = SafeAreasManager.shared
    @ObservedObject var referenceManager = ReferenceManager.shared
    
    @State private var showOpacityPopover: Bool = false
    @State private var showFontPopover: Bool = false
    
    var body: some View {
        ZStack {
            // Background with blur and customizable opacity
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .opacity(storage.preferences.opacity)
            
            // Tint background for high contrast & dark macOS feel
            Color.black.opacity(0.35 * storage.preferences.opacity)
            
            VStack(spacing: 0) {
                // Adaptive Two-Tier Header Bar
                headerView
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                
                Divider()
                    .background(Color.white.opacity(0.15))
                
                // Ghost mode notification banner (if active)
                if storage.preferences.isClickThrough {
                    ghostBannerView
                }
                
                // Main Content Body (Checklist, Notes, Audio, Sketch)
                switch storage.preferences.selectedTab {
                case 0: ChecklistView()
                case 1: NotesView()
                case 2: AudioNotesView()
                case 3: DrawingCanvasView()
                default: ChecklistView()
                }
            }
        }
        .frame(minWidth: 320, minHeight: 250)
    }
    
    // MARK: - Responsive Two-Tier Header
    
    private var headerView: some View {
        VStack(spacing: 6) {
            // Tier 1: Title / Drag Handle + Actions Bar
            HStack(spacing: 4) {
                // Title and Pin Button (High Layout Priority to NEVER squash or shift)
                HStack(spacing: 5) {
                    // Pin Button (Clicking pin hides the window)
                    Button(action: {
                        (NSApp.delegate as? AppDelegate)?.toggleWindow()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(storage.preferences.isPinned ? Color(red: 0.18, green: 0.78, blue: 0.35).opacity(0.28) : Color.white.opacity(0.12))
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(storage.preferences.isPinned ? Color(red: 0.18, green: 0.78, blue: 0.35).opacity(0.85) : Color.white.opacity(0.22), lineWidth: 1)
                            Image(systemName: storage.preferences.isPinned ? "pin.fill" : "pin.slash")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(storage.preferences.isPinned ? Color(red: 0.18, green: 0.78, blue: 0.35) : Color.white.opacity(0.55))
                        }
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .help("Скрыть окно (\(storage.preferences.toggleWindowHotkey.displayString))")
                    
                    // App Title
                    Text("FloatNote")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(1)
                        .fixedSize()
                }
                .layoutPriority(2)
                
                // Center Drag Area (flexible, fills available space, separate from buttons)
                WindowDragArea()
                    .frame(maxWidth: .infinity, maxHeight: 28)
                
                // Action Buttons with FULL-BODY RECTANGULAR HIT TARGETS (compact 26x26)
                HStack(spacing: 3) {
                    // Open Files Folder
                    Button(action: {
                        NSWorkspace.shared.open(AppConstants.filesDirectory)
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.09))
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            Image(systemName: "folder")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .help("Открыть папку файлов FloatNote")
                    
                    // Font Size Popover Button
                    Button(action: { showFontPopover.toggle() }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(showFontPopover ? Color.white.opacity(0.2) : Color.white.opacity(0.09))
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(showFontPopover ? Color.white.opacity(0.3) : Color.white.opacity(0.14), lineWidth: 1)
                            Image(systemName: "textformat.size")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .help("Размер текста")
                    .popover(isPresented: $showFontPopover) {
                        VStack(spacing: 8) {
                            Text("Размер шрифта: \(Int(storage.preferences.fontSize)) pt")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 6) {
                                Button(action: {
                                    if storage.preferences.fontSize > 10 {
                                        storage.preferences.fontSize -= 2
                                    }
                                }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.white.opacity(0.15))
                                        Image(systemName: "minus")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .frame(width: 28, height: 26)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .contentShape(Rectangle())
                                
                                Text("\(Int(storage.preferences.fontSize))")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .frame(width: 28)
                                
                                Button(action: {
                                    if storage.preferences.fontSize < 30 {
                                        storage.preferences.fontSize += 2
                                    }
                                }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.white.opacity(0.15))
                                        Image(systemName: "plus")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .frame(width: 28, height: 26)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .contentShape(Rectangle())
                            }
                            
                            HStack(spacing: 4) {
                                ForEach([12, 14, 18, 22], id: \.self) { size in
                                    Button("\(size)") {
                                        storage.preferences.fontSize = Double(size)
                                    }
                                    .font(.system(size: 11, weight: storage.preferences.fontSize == Double(size) ? .bold : .regular))
                                    .foregroundColor(storage.preferences.fontSize == Double(size) ? .accentColor : .white.opacity(0.85))
                                    .frame(width: 32, height: 24)
                                    .background(storage.preferences.fontSize == Double(size) ? Color.white.opacity(0.25) : Color.white.opacity(0.08))
                                    .cornerRadius(4)
                                    .contentShape(Rectangle())
                                    .buttonStyle(.plain)
                                    .contentShape(Rectangle())
                                }
                            }
                        }
                        .padding(10)
                    }
                    
                    // Opacity Quick Slider Button
                    Button(action: { showOpacityPopover.toggle() }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(showOpacityPopover ? Color.white.opacity(0.2) : Color.white.opacity(0.09))
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(showOpacityPopover ? Color.white.opacity(0.3) : Color.white.opacity(0.14), lineWidth: 1)
                            Image(systemName: "circle.lefthalf.filled")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .help("Прозрачность окна")
                    .popover(isPresented: $showOpacityPopover) {
                        VStack(spacing: 6) {
                            Text("Прозрачность: \(Int(storage.preferences.opacity * 100))%")
                                .font(.caption)
                            Slider(value: $storage.preferences.opacity, in: 0.15...1.0, step: 0.05)
                                .frame(width: 140)
                        }
                        .padding(10)
                    }
                    
                    // Click-Through (Ghost Mode) Toggle
                    Button(action: {
                        toggleGhostMode()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(storage.preferences.isClickThrough ? Color.yellow.opacity(0.28) : Color.white.opacity(0.09))
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(storage.preferences.isClickThrough ? Color.yellow.opacity(0.65) : Color.white.opacity(0.14), lineWidth: 1)
                            Image(systemName: storage.preferences.isClickThrough ? "cursorarrow.slash" : "cursorarrow")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(storage.preferences.isClickThrough ? .yellow : .white.opacity(0.9))
                        }
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .help(storage.preferences.isClickThrough ? "Отключить сквозной режим" : "Включить сквозной режим (\(storage.preferences.toggleGhostHotkey.displayString))")
                    
                    // Settings Button
                    Button(action: {
                        (NSApp.delegate as? AppDelegate)?.openSettings()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.09))
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            Image(systemName: "gearshape")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .help("Настройки")
                    
                    // Hide Button
                    Button(action: {
                        (NSApp.delegate as? AppDelegate)?.toggleWindow()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.09))
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            Image(systemName: "eye.slash")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .help("Скрыть окно (\(storage.preferences.toggleWindowHotkey.displayString))")
                }
            }
            
            // Tier 1.5: Companion Tools Bar
            HStack(spacing: 6) {
                // 9:16 Safe Areas
                Button(action: { safeAreas.toggle() }) {
                    HStack(spacing: 3) {
                        Image(systemName: "rectangle.split.3x3")
                            .font(.system(size: 9))
                        Text(safeAreas.mode == .vertical ? "9:16 Зоны" : "16:9 Сетка")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(safeAreas.isVisible ? Color.cyan.opacity(0.3) : Color.white.opacity(0.06))
                    .foregroundColor(safeAreas.isVisible ? .cyan : .white.opacity(0.8))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(safeAreas.isVisible ? Color.cyan.opacity(0.6) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .help("Сетка безопасных зон 9:16 / 16:9 и шпаргалка платформ")
                
                // Reference Overlay companion window
                Button(action: { referenceManager.toggle() }) {
                    HStack(spacing: 2) {
                        Image(systemName: "photo")
                            .font(.system(size: 9))
                        Text("Референс")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(referenceManager.isVisible ? Color.purple.opacity(0.3) : Color.white.opacity(0.06))
                    .foregroundColor(referenceManager.isVisible ? .purple : .white.opacity(0.8))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(referenceManager.isVisible ? Color.purple.opacity(0.6) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .help("Открыть плавающее окно референса поверх вьювера монтажки")
                
                // Timer companion window
                Button(action: { timerPanel.toggle() }) {
                    HStack(spacing: 2) {
                        Image(systemName: "timer")
                            .font(.system(size: 9))
                        Text("Таймер")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(timerPanel.isVisible ? Color.green.opacity(0.25) : Color.white.opacity(0.06))
                    .foregroundColor(timerPanel.isVisible ? .green : .white.opacity(0.8))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(timerPanel.isVisible ? Color.green.opacity(0.6) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .help("Открыть плавающее окно таймера / Помодоро")
                
                // Clipboard companion window
                Button(action: { clipboardPanel.toggle() }) {
                    HStack(spacing: 2) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 9))
                        Text("Буфер")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(clipboardPanel.isVisible ? Color.orange.opacity(0.25) : Color.white.opacity(0.06))
                    .foregroundColor(clipboardPanel.isVisible ? .orange : .white.opacity(0.8))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(clipboardPanel.isVisible ? Color.orange.opacity(0.6) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .help("Открыть отдельное окно истории буфера обмена")
                
                Spacer()
            }
            
            // Tier 2: Adaptive Full-Width Tabs Bar
            HStack(spacing: 3) {
                tabButton(title: "Чеклист", icon: "checkmark.square", index: 0)
                tabButton(title: "Заметки", icon: "note.text", index: 1)
                tabButton(title: "Аудио", icon: "mic.fill", index: 2)
                tabButton(title: "Скетч", icon: "pencil.tip.crop.circle", index: 3)
            }
            .padding(3)
            .background(Color.black.opacity(0.3))
            .cornerRadius(7)
        }
    }
    
    private func tabButton(title: String, icon: String, index: Int) -> some View {
        let isSelected = storage.preferences.selectedTab == index
        return Button(action: {
            storage.preferences.selectedTab = index
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.white.opacity(0.24) : Color.white.opacity(0.001))
                HStack(spacing: 5) {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                    Text(title)
                        .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                        .lineLimit(1)
                }
                .foregroundColor(isSelected ? .white : .white.opacity(0.65))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 28)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
    
    // MARK: - Ghost Banner
    
    private var ghostBannerView: some View {
        HStack(spacing: 8) {
            Image(systemName: "cursorarrow.slash")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.yellow)
            
            Text("Сквозной клик активен")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.yellow.opacity(0.95))
                .lineLimit(1)
            
            Spacer()
            
            Button(action: {
                toggleGhostMode()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.yellow)
                    Text("Отключить")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                }
                .frame(width: 80, height: 26)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .help("Отключить сквозной режим")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.75))
    }
    
    private func toggleGhostMode() {
        (NSApp.delegate as? AppDelegate)?.toggleGhost()
    }
    
    private func togglePin() {
        (NSApp.delegate as? AppDelegate)?.togglePin()
    }
}


