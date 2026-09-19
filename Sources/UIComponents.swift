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
    
    private var initialMouseLocation: NSPoint?
    private var initialWindowOrigin: NSPoint?
    private var isDragging: Bool = false
    
    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: isDragging ? .closedHand : .openHand)
    }
    
    override func mouseDown(with event: NSEvent) {
        initialMouseLocation = NSEvent.mouseLocation
        initialWindowOrigin = window?.frame.origin
        isDragging = true
        window?.invalidateCursorRects(for: self)
        window?.performDrag(with: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let startMouse = initialMouseLocation,
              let startOrigin = initialWindowOrigin,
              let win = window else {
            super.mouseDragged(with: event)
            return
        }
        let currentMouse = NSEvent.mouseLocation
        let deltaX = currentMouse.x - startMouse.x
        let deltaY = currentMouse.y - startMouse.y
        let newOrigin = NSPoint(x: startOrigin.x + deltaX, y: startOrigin.y + deltaY)
        win.setFrameOrigin(newOrigin)
    }
    
    override func mouseUp(with event: NSEvent) {
        initialMouseLocation = nil
        initialWindowOrigin = nil
        isDragging = false
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
