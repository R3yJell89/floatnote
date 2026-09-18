import AppKit
import SwiftUI
import Carbon

extension Notification.Name {
    static let undoRequested = Notification.Name("FloatNoteUndoRequested")
}

final class FloatingPanel: NSPanel {
    private var savePositionTimer: Timer?
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [
                .titled,
                .resizable,
                .closable,
                .fullSizeContentView,
                .nonactivatingPanel
            ],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.setPinned(StorageManager.shared.preferences.isPinned)
        
        self.hidesOnDeactivate = false
        // Dragging is handled only via the top header bar to prevent drawing gestures from moving the window
        self.isMovableByWindowBackground = false
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
        
        // Transparent styling for SwiftUI background material
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        
        // Minimum size
        self.minSize = NSSize(width: 320, height: 260)
        self.becomesKeyOnlyIfNeeded = false
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMoveOrResize),
            name: NSWindow.didMoveNotification,
            object: self
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMoveOrResize),
            name: NSWindow.didResizeNotification,
            object: self
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopTrackingMouse()
    }
    
    @objc private func windowDidMoveOrResize() {
        savePositionTimer?.invalidate()
        savePositionTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            let f = self.frame
            guard f.width >= 100, f.height >= 100 else { return }
            StorageManager.shared.preferences.windowX = Double(f.origin.x)
            StorageManager.shared.preferences.windowY = Double(f.origin.y)
            StorageManager.shared.preferences.windowWidth = Double(f.size.width)
            StorageManager.shared.preferences.windowHeight = Double(f.size.height)
        }
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    override func becomeKey() {
        super.becomeKey()
    }
    
    override func sendEvent(_ event: NSEvent) {
        if StorageManager.shared.preferences.isClickThrough {
            checkMousePosition(NSEvent.mouseLocation)
        }
        if event.type == .keyDown && event.modifierFlags.contains(.command) {
            if event.keyCode == UInt16(kVK_ANSI_A) {
                if let tv = activeTextView() {
                    tv.selectAll(nil)
                    return
                }
            } else if event.keyCode == UInt16(kVK_ANSI_C) {
                if let tv = activeTextView() {
                    tv.copy(nil)
                    return
                }
            } else if event.keyCode == UInt16(kVK_ANSI_V) {
                if let tv = activeTextView() {
                    tv.paste(nil)
                    return
                }
            } else if event.keyCode == UInt16(kVK_ANSI_X) {
                if let tv = activeTextView() {
                    tv.cut(nil)
                    return
                }
            } else if event.keyCode == UInt16(kVK_ANSI_Z) {
                if let tv = activeTextView() {
                    if event.modifierFlags.contains(.shift) {
                        tv.undoManager?.redo()
                    } else {
                        tv.undoManager?.undo()
                    }
                    return
                }
            }
        }
        super.sendEvent(event)
    }
    
    func setPinned(_ pinned: Bool) {
        if pinned {
            self.level = NSWindow.Level(rawValue: 1002)
            self.collectionBehavior = [
                .canJoinAllSpaces,
                .fullScreenAuxiliary,
                .stationary,
                .ignoresCycle
            ]
            self.orderFrontRegardless()
        } else {
            self.level = .normal
            self.collectionBehavior = [
                .canJoinAllSpaces,
                .fullScreenAuxiliary,
                .ignoresCycle
            ]
            self.orderFrontRegardless()
        }
    }
    
    private var mousePollTimer: Timer?
    
    func setClickThrough(_ enabled: Bool) {
        if enabled {
            startTrackingMouse()
        } else {
            stopTrackingMouse()
            self.ignoresMouseEvents = false
        }
    }
    
    private func startTrackingMouse() {
        stopTrackingMouse()
        
        checkMousePosition(NSEvent.mouseLocation)
        
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .leftMouseDown]) { [weak self] _ in
            self?.checkMousePosition(NSEvent.mouseLocation)
        }
        
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .leftMouseDown]) { [weak self] event in
            self?.checkMousePosition(NSEvent.mouseLocation)
            return event
        }
        
        // High-frequency polling (60fps / 16ms) scheduled on .common runloop mode so it runs during dragging and clicks
        let timer = Timer(timeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.checkMousePosition(NSEvent.mouseLocation)
        }
        RunLoop.main.add(timer, forMode: .common)
        mousePollTimer = timer
    }
    
    private func stopTrackingMouse() {
        mousePollTimer?.invalidate()
        mousePollTimer = nil
        if let m = globalMouseMonitor {
            NSEvent.removeMonitor(m)
            globalMouseMonitor = nil
        }
        if let m = localMouseMonitor {
            NSEvent.removeMonitor(m)
            localMouseMonitor = nil
        }
    }
    
    private func checkMousePosition(_ screenPoint: NSPoint) {
        guard StorageManager.shared.preferences.isClickThrough else {
            if self.ignoresMouseEvents {
                self.ignoresMouseEvents = false
            }
            return
        }
        
        // Full header area: top 135pt generously covers the header bar, action buttons, tab switcher, and ghost banner with generous safety margin
        let headerHeight: CGFloat = 135
        let headerRect = NSRect(
            x: self.frame.origin.x,
            y: self.frame.maxY - headerHeight,
            width: self.frame.width,
            height: headerHeight
        )
        
        let isInsideHeader = headerRect.contains(screenPoint)
        
        if isInsideHeader {
            // Mouse is anywhere over header, tabs, or banner -> 100% interactive
            if self.ignoresMouseEvents {
                self.ignoresMouseEvents = false
            }
        } else {
            // Mouse is in body / content area -> pass click straight through to underlying editor / background window!
            if !self.ignoresMouseEvents {
                self.ignoresMouseEvents = true
            }
        }
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command) else {
            return super.performKeyEquivalent(with: event)
        }
        
        // Match by physical keyCode so Russian/Cyrillic layout works identically to English
        switch event.keyCode {
        case UInt16(kVK_ANSI_A): // Cmd + A (Select All)
            if let textView = activeTextView() {
                textView.selectAll(nil)
                return true
            }
            if NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: self) {
                return true
            }
            
        case UInt16(kVK_ANSI_C): // Cmd + C (Copy)
            if let textView = activeTextView() {
                textView.copy(nil)
                return true
            }
            if NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self) {
                return true
            }
            
        case UInt16(kVK_ANSI_V): // Cmd + V (Paste)
            if let textView = activeTextView() {
                textView.paste(nil)
                return true
            }
            if NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self) {
                return true
            }
            
        case UInt16(kVK_ANSI_X): // Cmd + X (Cut)
            if let textView = activeTextView() {
                textView.cut(nil)
                return true
            }
            if NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self) {
                return true
            }
            
        case UInt16(kVK_ANSI_Z): // Cmd + Z (Undo / Redo)
            if event.modifierFlags.contains(.shift) {
                if let textView = activeTextView(), let undo = textView.undoManager, undo.canRedo {
                    undo.redo()
                    return true
                }
                if NSApp.sendAction(Selector(("redo:")), to: nil, from: self) {
                    return true
                }
            } else {
                if let textView = activeTextView(), let undo = textView.undoManager, undo.canUndo {
                    undo.undo()
                    return true
                }
                if NSApp.sendAction(Selector(("undo:")), to: nil, from: self) {
                    return true
                }
                NotificationCenter.default.post(name: .undoRequested, object: nil)
                return true
            }
            
        default:
            break
        }
        
        return super.performKeyEquivalent(with: event)
    }
    
    private func activeTextView() -> NSTextView? {
        if let tv = self.firstResponder as? NSTextView {
            return tv
        }
        if let fieldEditor = self.fieldEditor(false, for: nil) as? NSTextView, self.firstResponder == fieldEditor {
            return fieldEditor
        }
        // Fallback: search for any focused or present NSTextView in the window hierarchy
        if let root = self.contentView {
            return findFirstTextView(in: root)
        }
        return nil
    }
    
    private func findFirstTextView(in view: NSView) -> NSTextView? {
        if let tv = view as? NSTextView {
            return tv
        }
        for sub in view.subviews {
            if let found = findFirstTextView(in: sub) {
                return found
            }
        }
        return nil
    }
}
