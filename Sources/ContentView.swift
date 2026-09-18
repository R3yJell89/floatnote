import SwiftUI
import AppKit

// MARK: - Visual Effect Background

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .active
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// MARK: - Window Drag Area

struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowDragNSView {
        WindowDragNSView()
    }
    func updateNSView(_ nsView: WindowDragNSView, context: Context) {}
}

final class WindowDragNSView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

// MARK: - Native Mac Text Editor

class CustomTextView: NSTextView {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) {
            switch event.keyCode {
            case 0: // Cmd + A (Select All)
                self.selectAll(nil)
                return true
            case 8: // Cmd + C (Copy)
                self.copy(nil)
                return true
            case 9: // Cmd + V (Paste)
                self.paste(nil)
                return true
            case 7: // Cmd + X (Cut)
                self.cut(nil)
                return true
            case 6: // Cmd + Z (Undo / Redo)
                if event.modifierFlags.contains(.shift) {
                    self.undoManager?.redo()
                } else {
                    self.undoManager?.undo()
                }
                return true
            default:
                break
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}

struct MacEditorView: NSViewRepresentable {
    @Binding var text: String
    var fontSize: CGFloat
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = CustomTextView()
        
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = NSFont.systemFont(ofSize: fontSize)
        textView.textColor = .white
        textView.insertionPointColor = .white
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.autoresizingMask = [.width]
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.minSize = NSSize(width: 0, height: 0)
        
        scrollView.documentView = textView
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        
        textView.string = text
        context.coordinator.textView = textView
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        if textView.string != text {
            textView.string = text
        }
        if textView.font?.pointSize != fontSize {
            textView.font = NSFont.systemFont(ofSize: fontSize)
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MacEditorView
        weak var textView: NSTextView?
        
        init(_ parent: MacEditorView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let tv = textView else { return }
            parent.text = tv.string
        }
    }
}

// MARK: - Main Content View

struct ContentView: View {
    @ObservedObject var storage = StorageManager.shared
    @ObservedObject var templateManager = TemplateManager.shared
    @ObservedObject var timerPanel = TimerPanelManager.shared
    @ObservedObject var clipboardPanel = ClipboardPanelManager.shared
    @ObservedObject var safeAreas = SafeAreasManager.shared
    @ObservedObject var speech = SpeechDictationManager.shared
    
    @State private var newTaskText: String = ""
    @State private var showOpacityPopover: Bool = false
    @State private var showFontPopover: Bool = false
    @FocusState private var isNewTaskFocused: Bool
    
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
                case 0: checklistView
                case 1: notesView
                case 2: AudioNotesView()
                case 3: DrawingCanvasView()
                default: checklistView
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
                        let baseDir = URL(fileURLWithPath: "/Users/r3yjell/Documents/Давинчи/FloatNote_Files")
                        NSWorkspace.shared.open(baseDir)
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
                        Image(systemName: "rectangle.portrait.split.2x1")
                            .font(.system(size: 9))
                        Text("9:16 Зоны")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .padding(.horizontal, 6)
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
                .help("Сетка безопасных зон 9:16 (Reels / TikTok / Shorts)")
                
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
    
    // MARK: - Checklist View
    
    private var checklistView: some View {
        VStack(spacing: 0) {
            // Checklist Actions & Templates Strip
            HStack(spacing: 6) {
                // Templates Menu
                Menu {
                    Section("Готовые шаблоны") {
                        ForEach(TemplateManager.builtInTemplates) { tmpl in
                            Button(tmpl.name) {
                                templateManager.applyTemplate(tmpl, replace: false)
                            }
                        }
                    }
                    if !templateManager.customTemplates.isEmpty {
                        Section("Мои шаблоны") {
                            ForEach(templateManager.customTemplates) { tmpl in
                                Button(tmpl.name) {
                                    templateManager.applyTemplate(tmpl, replace: false)
                                }
                            }
                        }
                    }
                    Divider()
                    Button("💾 Сохранить список как шаблон...") {
                        saveCurrentAsTemplatePrompt()
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 10))
                        Text("Шаблоны")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(4)
                    .foregroundColor(.white.opacity(0.85))
                }
                .menuStyle(.borderlessButton)
                
                Spacer()
                
                // Quick Insert Timecode button
                Button(action: {
                    let pb = NSPasteboard.general.string(forType: .string) ?? ""
                    let tcPattern = #"(\d{2}:\d{2}:\d{2}[:;]\d{2})"#
                    var tcToInsert = "01:00:00:00"
                    if let range = pb.range(of: tcPattern, options: .regularExpression) {
                        tcToInsert = String(pb[range])
                    }
                    if newTaskText.isEmpty {
                        newTaskText = "[\(tcToInsert)] "
                    } else {
                        newTaskText += " [\(tcToInsert)]"
                    }
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text("Таймкод")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.cyan.opacity(0.15))
                    .foregroundColor(.cyan)
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Вставить таймкод (из буфера или шаблон [01:00:00:00])")
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)
            .padding(.bottom, 2)
            
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach($storage.items) { $item in
                        checklistItemRow(item: $item)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Bottom Add & Status Bar
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 15))
                    
                    TextField("Новая задача... (Enter)", text: $newTaskText)
                        .textFieldStyle(.plain)
                        .font(.system(size: storage.preferences.fontSize))
                        .foregroundColor(.white)
                        .focused($isNewTaskFocused)
                        .onSubmit {
                            addNewTask()
                        }
                    
                    // Voice dictation button
                    Button(action: {
                        speech.toggleDictation { dictatedText in
                            if self.newTaskText.isEmpty {
                                self.newTaskText = dictatedText
                            } else {
                                self.newTaskText += " " + dictatedText
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(speech.isListening ? Color.red.opacity(0.3) : Color.white.opacity(0.08))
                            Image(systemName: speech.isListening ? "waveform" : "mic.fill")
                                .font(.system(size: 10))
                                .foregroundColor(speech.isListening ? .red : .white.opacity(0.75))
                        }
                        .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                    .help(speech.isListening ? "Остановить запись голоса" : "Голосовой ввод задачи (Apple Speech)")
                    
                    if !newTaskText.isEmpty {
                        Button(action: addNewTask) {
                            Text("Добавить")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08))
                .cornerRadius(6)
                
                HStack {
                    let completedCount = storage.items.filter { $0.isCompleted }.count
                    Text("\(completedCount) из \(storage.items.count) выполнено")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Spacer()
                    
                    if completedCount > 0 {
                        Button("Очистить выполненные") {
                            storage.items.removeAll { $0.isCompleted }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(8)
            .background(Color.black.opacity(0.25))
        }
    }
    
    private func extractTimecode(from text: String) -> String? {
        let pattern = #"\b(\d{2}:\d{2}:\d{2}[:;]\d{2})\b"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            return String(text[range])
        }
        return nil
    }
    
    private func checklistItemRow(item: Binding<ChecklistItem>) -> some View {
        let tc = extractTimecode(from: item.wrappedValue.text)
        
        return HStack(alignment: .center, spacing: 6) {
            Button(action: {
                item.wrappedValue.isCompleted.toggle()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.001))
                    Image(systemName: item.wrappedValue.isCompleted ? "checkmark.square.fill" : "square")
                        .font(.system(size: max(16, CGFloat(storage.preferences.fontSize) + 2)))
                        .foregroundColor(item.wrappedValue.isCompleted ? .accentColor : .white.opacity(0.75))
                }
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            
            TextField("", text: item.text)
                .textFieldStyle(.plain)
                .font(.system(size: storage.preferences.fontSize))
                .foregroundColor(item.wrappedValue.isCompleted ? .white.opacity(0.4) : .white)
                .strikethrough(item.wrappedValue.isCompleted, color: .white.opacity(0.4))
            
            // Clickable Timecode Badge (Copies TC to clipboard)
            if let tc = tc {
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(tc, forType: .string)
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 7))
                        Text(tc)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.cyan.opacity(0.2))
                    .foregroundColor(.cyan)
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .help("Скопировать таймкод \(tc) в буфер обмена")
            }
            
            Button(action: {
                if let idx = storage.items.firstIndex(where: { $0.id == item.wrappedValue.id }) {
                    storage.items.remove(at: idx)
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.001))
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.04))
        .cornerRadius(6)
    }
    
    // MARK: - Notes View
    
    private var notesView: some View {
        VStack(spacing: 0) {
            // Notes Toolbar
            HStack(spacing: 6) {
                // Timecode
                Button(action: {
                    let pb = NSPasteboard.general.string(forType: .string) ?? ""
                    let tcPattern = #"(\d{2}:\d{2}:\d{2}[:;]\d{2})"#
                    var tcToInsert = "01:00:00:00"
                    if let range = pb.range(of: tcPattern, options: .regularExpression) {
                        tcToInsert = String(pb[range])
                    }
                    if storage.notesText.isEmpty {
                        storage.notesText = "[\(tcToInsert)] "
                    } else {
                        storage.notesText += "\n[\(tcToInsert)] "
                    }
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text("Таймкод")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.cyan.opacity(0.15))
                    .foregroundColor(.cyan)
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Вставить таймкод (из буфера или шаблон [01:00:00:00])")
                
                // Voice Dictation
                Button(action: {
                    speech.toggleDictation { dictated in
                        if storage.notesText.isEmpty {
                            storage.notesText = dictated
                        } else {
                            storage.notesText += "\n" + dictated
                        }
                    }
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: speech.isListening ? "waveform" : "mic.fill")
                            .font(.system(size: 10))
                        Text(speech.isListening ? "Слушаю..." : "Диктовка")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(speech.isListening ? Color.red.opacity(0.3) : Color.white.opacity(0.08))
                    .foregroundColor(speech.isListening ? .red : .white.opacity(0.85))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help(speech.isListening ? "Остановить запись" : "Надиктовать речь в заметки")
                
                // Clipboard history toggle
                Button(action: {
                    clipboardPanel.toggle()
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 10))
                        Text("Буфер")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08))
                    .foregroundColor(.white.opacity(0.85))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Открыть историю буфера обмена")
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.2))
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            MacEditorView(text: $storage.notesText, fontSize: CGFloat(storage.preferences.fontSize))
                .padding(8)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack {
                Text("\(storage.notesText.count) символов")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("Автосохранение")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.25))
        }
    }
    
    // MARK: - Actions
    
    private func addNewTask() {
        let trimmed = newTaskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        storage.items.append(ChecklistItem(text: trimmed, isCompleted: false))
        newTaskText = ""
        isNewTaskFocused = true
    }
    
    private func saveCurrentAsTemplatePrompt() {
        let alert = NSAlert()
        alert.messageText = "Сохранить чеклист как шаблон"
        alert.informativeText = "Введите название для нового шаблона:"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Сохранить")
        alert.addButton(withTitle: "Отмена")
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        input.placeholderString = "Мой шаблон монтажа"
        alert.accessoryView = input
        
        if alert.runModal() == .alertFirstButtonReturn {
            let name = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                templateManager.saveCurrentAsTemplate(name: name, items: storage.items)
            }
        }
    }
    
    private func toggleGhostMode() {
        (NSApp.delegate as? AppDelegate)?.toggleGhost()
    }
    
    private func togglePin() {
        (NSApp.delegate as? AppDelegate)?.togglePin()
    }
}

// MARK: - Audio Notes View

struct AudioNotesView: View {
    @ObservedObject var audioManager = AudioManager.shared
    @State private var copiedNoteId: String?
    @State private var addedToNotesId: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Recording Controls Area
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    // Record / Stop Button
                    Button(action: {
                        if audioManager.isRecording {
                            audioManager.stopRecording()
                        } else {
                            audioManager.startRecording()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(audioManager.isRecording ? Color.red : Color.red.opacity(0.85))
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: audioManager.isRecording ? 2 : 0)
                                    )
                            Text(audioManager.isRecording ? "Стоп" : "Запись голоса")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(audioManager.isRecording ? Color.red.opacity(0.3) : Color.white.opacity(0.12))
                        .cornerRadius(7)
                    }
                    .buttonStyle(.plain)
                    
                    if audioManager.isRecording {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text(formatTime(audioManager.recordingDuration))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.red)
                        }
                    } else {
                        Text("\(audioManager.audioNotes.count) записей")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        NSWorkspace.shared.open(audioManager.audioFolderURL)
                    }) {
                        Image(systemName: "folder")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 26, height: 26)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                    .help("Открыть папку Аудио в Finder")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .background(Color.black.opacity(0.3))
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Audio List
            if audioManager.audioNotes.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "mic.slash")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.3))
                    Text("Нет голосовых записей")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Text("Нажмите «Запись голоса» для создания заметок")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.35))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(audioManager.audioNotes) { note in
                            audioNoteRow(note: note)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    private func audioNoteRow(note: AudioNote) -> some View {
        let isCurrentlyPlaying = audioManager.isPlaying && audioManager.currentlyPlayingURL == note.url
        
        return VStack(alignment: .leading, spacing: 6) {
            // Player Controls Row
            HStack(spacing: 8) {
                Button(action: {
                    audioManager.play(url: note.url)
                }) {
                    ZStack {
                        Color.white.opacity(0.001)
                        Image(systemName: isCurrentlyPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(isCurrentlyPlaying ? .accentColor : .white.opacity(0.95))
                    }
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(note.durationString)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Re-transcribe if needed
                if note.transcript == nil && !note.isTranscribing {
                    Button(action: {
                        audioManager.transcribeAudio(url: note.url)
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.08))
                            Image(systemName: "waveform.badge.magnifyingglass")
                                .font(.system(size: 12))
                                .foregroundColor(.accentColor)
                        }
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .help("Распознать речь")
                }
                
                // Reveal in Finder
                Button(action: {
                    audioManager.revealInFinder(url: note.url)
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                        Image(systemName: "folder")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .help("Показать в Finder")
                
                // Delete
                Button(action: {
                    audioManager.delete(url: note.url)
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.85))
                    }
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .help("Удалить запись")
            }
            
            // Transcription Display & Actions
            if note.isTranscribing {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 14, height: 14)
                    Text("Распознавание речи...")
                        .font(.system(size: 10))
                        .italic()
                        .foregroundColor(.yellow.opacity(0.9))
                }
                .padding(.horizontal, 4)
            } else if let transcript = note.transcript, !transcript.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(transcript)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            audioManager.copyTranscriptToClipboard(text: transcript)
                            copiedNoteId = note.id
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                if copiedNoteId == note.id { copiedNoteId = nil }
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: copiedNoteId == note.id ? "checkmark" : "doc.on.doc")
                                Text(copiedNoteId == note.id ? "Скопировано!" : "Копировать")
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        
                        Button(action: {
                            audioManager.appendToNotes(text: transcript, title: note.name)
                            addedToNotesId = note.id
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                if addedToNotesId == note.id { addedToNotesId = nil }
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: addedToNotesId == note.id ? "checkmark" : "note.text.badge.plus")
                                Text(addedToNotesId == note.id ? "Добавлено!" : "В заметки")
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.green.opacity(0.9))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        
                        Spacer()
                    }
                    .padding(.top, 2)
                }
                .padding(6)
                .background(Color.white.opacity(0.06))
                .cornerRadius(6)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
        .cornerRadius(6)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        let mins = s / 60
        let secs = s % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
