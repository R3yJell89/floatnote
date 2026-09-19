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
    
    private var isDragging: Bool = false
    
    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: isDragging ? .closedHand : .openHand)
    }
    
    override func mouseDown(with event: NSEvent) {
        isDragging = true
        window?.invalidateCursorRects(for: self)
        window?.performDrag(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        isDragging = false
        window?.invalidateCursorRects(for: self)
        super.mouseUp(with: event)
    }
}

// MARK: - Window Resize Area (Proportional diagonal resize)

struct WindowResizeArea: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowResizeNSView {
        WindowResizeNSView()
    }
    func updateNSView(_ nsView: WindowResizeNSView, context: Context) {}
}

final class WindowResizeNSView: NSView {
    private var initialMouseLocation: NSPoint?
    private var initialWindowFrame: NSRect?
    private var isResizing: Bool = false
    
    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: isResizing ? .closedHand : .openHand)
    }
    
    override func mouseDown(with event: NSEvent) {
        initialMouseLocation = NSEvent.mouseLocation
        initialWindowFrame = window?.frame
        isResizing = true
        window?.invalidateCursorRects(for: self)
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let startMouse = initialMouseLocation,
              let startFrame = initialWindowFrame,
              let win = window else {
            super.mouseDragged(with: event)
            return
        }
        
        let currentMouse = NSEvent.mouseLocation
        let deltaX = currentMouse.x - startMouse.x
        let deltaY = -(currentMouse.y - startMouse.y) // dragging down increases size in bottom corner
        let delta = (deltaX + deltaY) / 2.0
        
        let isVertical = win.aspectRatio.width < win.aspectRatio.height
        let ratio: CGFloat = isVertical ? (9.0 / 16.0) : (16.0 / 9.0)
        let minW: CGFloat = isVertical ? 240.0 : 360.0
        
        var newWidth = max(minW, startFrame.width + delta)
        var newHeight = newWidth / ratio
        
        if let screen = win.screen ?? NSScreen.main {
            let maxW = screen.visibleFrame.width * 0.95
            let maxH = screen.visibleFrame.height * 0.95
            if newWidth > maxW {
                newWidth = maxW
                newHeight = newWidth / ratio
            }
            if newHeight > maxH {
                newHeight = maxH
                newWidth = newHeight * ratio
            }
        }
        
        // Pin the top-left origin so resizing from bottom-right expands downwards and to the right
        let newOriginY = startFrame.maxY - newHeight
        let newFrame = NSRect(x: startFrame.minX, y: newOriginY, width: newWidth, height: newHeight)
        win.setFrame(newFrame, display: true)
    }
    
    override func mouseUp(with event: NSEvent) {
        initialMouseLocation = nil
        initialWindowFrame = nil
        isResizing = false
        window?.invalidateCursorRects(for: self)
        super.mouseUp(with: event)
    }
}

// MARK: - Native macOS Traffic Light Window Buttons (Close & Minimize)

struct WindowTrafficLights: View {
    @State private var isHoveringAll = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Close Button (Red)
            Button(action: {
                (NSApp.delegate as? AppDelegate)?.toggleWindow()
            }) {
                ZStack {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.37, blue: 0.34))
                        .frame(width: 12, height: 12)
                    Circle()
                        .stroke(Color.black.opacity(0.18), lineWidth: 0.5)
                        .frame(width: 12, height: 12)
                    if isHoveringAll {
                        Image(systemName: "xmark")
                            .font(.system(size: 7, weight: .black))
                            .foregroundColor(Color.black.opacity(0.65))
                    }
                }
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Закрыть окно FloatNote")
            
            // Minimize Button (Yellow)
            Button(action: {
                (NSApp.delegate as? AppDelegate)?.toggleWindow()
            }) {
                ZStack {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.74, blue: 0.18))
                        .frame(width: 12, height: 12)
                    Circle()
                        .stroke(Color.black.opacity(0.18), lineWidth: 0.5)
                        .frame(width: 12, height: 12)
                    if isHoveringAll {
                        Image(systemName: "minus")
                            .font(.system(size: 7, weight: .black))
                            .foregroundColor(Color.black.opacity(0.65))
                    }
                }
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Свернуть окно FloatNote")
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHoveringAll = hovering
            }
        }
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

// MARK: - Lightweight Localization Helper

enum L10n {
    static var isRu: Bool {
        StorageManager.shared.preferences.appLanguage == .ru
    }
    
    // Tabs
    static var tabChecklist: String { isRu ? "Чеклист" : "Checklist" }
    static var tabNotes: String { isRu ? "Заметки" : "Notes" }
    static var tabAudio: String { isRu ? "Аудио" : "Audio" }
    static var tabSketch: String { isRu ? "Скетч" : "Sketch" }
    
    // Header & Companion tools
    static var toolSafeAreas: String { isRu ? "Зоны" : "Safe Areas" }
    static var toolReference: String { isRu ? "Референс" : "Reference" }
    static var toolTimer: String { isRu ? "Таймер" : "Timer" }
    static var toolClipboard: String { isRu ? "Буфер" : "Clipboard" }
    
    static var pinTooltip: String { isRu ? "Закрепить поверх всех окон" : "Pin on top of all windows" }
    static var unpinTooltip: String { isRu ? "Открепить окно" : "Unpin window" }
    static var fontSizeTooltip: String { isRu ? "Размер текста" : "Font size" }
    static var opacityTooltip: String { isRu ? "Прозрачность окна" : "Window opacity" }
    static var ghostModeTooltip: String { isRu ? "Сквозной клик (Ghost mode)" : "Click-through (Ghost mode)" }
    static var settingsTooltip: String { isRu ? "Настройки" : "Settings" }
    static var hideTooltip: String { isRu ? "Скрыть окно" : "Hide window" }
    
    // Notes & Checklist
    static var timecodeBtn: String { isRu ? "Таймкод" : "Timecode" }
    static var dictationBtn: String { isRu ? "Диктовка" : "Dictation" }
    static var dictationListening: String { isRu ? "Слушаю..." : "Listening..." }
    static var clipboardBtn: String { isRu ? "Буфер" : "Clipboard" }
    static var charactersCount: String { isRu ? "символов" : "characters" }
    static var autoSaved: String { isRu ? "Автосохранение" : "Auto-saved" }
    
    static var newTaskPlaceholder: String { isRu ? "Новая задача... (Enter)" : "New task... (Enter)" }
    static var addBtn: String { isRu ? "Добавить" : "Add" }
    static var templatesBtn: String { isRu ? "Шаблоны" : "Templates" }
    static var markersBtn: String { isRu ? "Маркеры" : "Markers" }
}

