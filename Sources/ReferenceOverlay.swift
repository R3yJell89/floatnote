import SwiftUI
import AppKit

// MARK: - Floating Reference Image HUD

final class ReferenceManager: ObservableObject {
    static let shared = ReferenceManager()
    
    @Published var isVisible: Bool = false
    @Published var isLocked: Bool = false
    @Published var opacity: Double = 0.5
    @Published var referenceImage: NSImage? = nil
    
    private var panel: NSPanel?
    
    private init() {}
    
    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }
    
    func show() {
        if panel == nil {
            setupPanel()
        }
        panel?.orderFrontRegardless()
        isVisible = true
    }
    
    func hide() {
        panel?.orderOut(nil)
        isVisible = false
    }
    
    func toggleLock() {
        isLocked.toggle()
        panel?.ignoresMouseEvents = isLocked
    }
    
    private func setupPanel() {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 100, y: 100, width: 800, height: 600)
        let w: CGFloat = 420
        let h: CGFloat = 280
        let x = screen.midX - (w / 2.0)
        let y = screen.midY - (h / 2.0)
        
        let p = NSPanel(
            contentRect: NSRect(x: x, y: y, width: w, height: h),
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )
        
        p.isFloatingPanel = true
        p.level = NSWindow.Level(rawValue: 1001)
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.minSize = NSSize(width: 200, height: 150)
        p.ignoresMouseEvents = isLocked
        
        let hosting = FirstMouseHostingView(rootView: ReferenceOverlayView())
        p.contentView = hosting
        
        self.panel = p
    }
}

struct ReferenceOverlayView: View {
    @ObservedObject var manager = ReferenceManager.shared
    @State private var isDropTargeted: Bool = false
    
    var body: some View {
        ZStack {
            // Reference image area
            if let img = manager.referenceImage {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(manager.opacity)
                    .allowsHitTesting(false)
            } else {
                // Dropzone placeholder
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.4))
                    Text("Перетащите референс кадра сюда")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Text("или вставьте из буфера (⌘V)")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(isDropTargeted ? 0.6 : 0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isDropTargeted ? Color.cyan : Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                )
                .padding(6)
            }
            
            // Frame border
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                .allowsHitTesting(false)
            
            // Floating control toolbar
            VStack {
                HStack(spacing: 6) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.cyan)
                    
                    Text("Референс")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                    
                    WindowDragArea()
                        .frame(height: 18)
                    
                    // Opacity Slider
                    HStack(spacing: 4) {
                        Image(systemName: "circle.lefthalf.filled")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.6))
                        Slider(value: $manager.opacity, in: 0.1...1.0)
                            .frame(width: 60)
                            .controlSize(.mini)
                    }
                    
                    // Paste from clipboard
                    Button(action: {
                        if let img = NSImage(pasteboard: NSPasteboard.general) {
                            manager.referenceImage = img
                        }
                    }) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .help("Вставить изображение из буфера обмена")
                    
                    // Clear image
                    if manager.referenceImage != nil {
                        Button(action: { manager.referenceImage = nil }) {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                        .help("Удалить референс")
                    }
                    
                    // Lock toggle
                    Button(action: { manager.toggleLock() }) {
                        Image(systemName: manager.isLocked ? "lock.fill" : "lock.open")
                            .font(.system(size: 10))
                            .foregroundColor(manager.isLocked ? .yellow : .white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .help(manager.isLocked ? "Разблокировать (для перемещения)" : "Заблокировать (сквозной клик)")
                    
                    // Close
                    Button(action: { manager.hide() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .help("Закрыть референс")
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.85))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .padding(.top, 4)
                
                Spacer()
            }
        }
        .onDrop(of: ["public.file-url", "public.image"], isTargeted: $isDropTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, _ in
                if let data = data, let img = NSImage(data: data) {
                    DispatchQueue.main.async {
                        self.manager.referenceImage = img
                    }
                }
            }
            return true
        }
    }
}
