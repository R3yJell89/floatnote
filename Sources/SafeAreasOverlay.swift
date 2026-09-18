import SwiftUI
import AppKit

// MARK: - Safe Areas Overlay Window & View

final class SafeAreasManager: ObservableObject {
    static let shared = SafeAreasManager()
    
    @Published var isVisible: Bool = false
    @Published var isLocked: Bool = false // When locked, ignoresMouseEvents = true (100% click-through)
    
    private var overlayPanel: NSPanel?
    
    private init() {}
    
    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }
    
    func show() {
        if overlayPanel == nil {
            setupPanel()
        }
        overlayPanel?.orderFrontRegardless()
        isVisible = true
    }
    
    func hide() {
        overlayPanel?.orderOut(nil)
        isVisible = false
    }
    
    func toggleLock() {
        isLocked.toggle()
        overlayPanel?.ignoresMouseEvents = isLocked
    }
    
    private func setupPanel() {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        // Default size 9:16 aspect ratio in viewer center
        let height: CGFloat = min(screen.height * 0.75, 720)
        let width: CGFloat = height * (9.0 / 16.0)
        let x = screen.midX - (width / 2.0)
        let y = screen.midY - (height / 2.0)
        
        let panel = NSPanel(
            contentRect: NSRect(x: x, y: y, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )
        
        panel.isFloatingPanel = true
        panel.level = NSWindow.Level(rawValue: 1001)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.aspectRatio = NSSize(width: 9, height: 16)
        panel.minSize = NSSize(width: 225, height: 400)
        panel.ignoresMouseEvents = isLocked
        
        let hostingView = FirstMouseHostingView(rootView: SafeAreasView())
        panel.contentView = hostingView
        
        self.overlayPanel = panel
    }
}

// MARK: - Safe Areas SwiftUI View

struct SafeAreasView: View {
    @ObservedObject var manager = SafeAreasManager.shared
    @State private var showLabels: Bool = true
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // Background tint (ultra faint to indicate bounds)
                Color.black.opacity(0.04)
                
                // Outer 9:16 Border
                Rectangle()
                    .stroke(Color.cyan.opacity(0.8), lineWidth: 2)
                
                // Safe Area Guides
                // Top Safe Zone (15% height - Reels / TikTok profile and search bar)
                let topH = h * 0.14
                Path { path in
                    path.move(to: CGPoint(x: 0, y: topH))
                    path.addLine(to: CGPoint(x: w, y: topH))
                }
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .foregroundColor(Color.yellow.opacity(0.85))
                
                // Bottom Safe Zone (22% height - Caption, sound title, navigation bar)
                let bottomY = h * (1.0 - 0.22)
                Path { path in
                    path.move(to: CGPoint(x: 0, y: bottomY))
                    path.addLine(to: CGPoint(x: w, y: bottomY))
                }
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .foregroundColor(Color.red.opacity(0.85))
                
                // Right Action Column Safe Zone (18% width - Likes, Comments, Share buttons)
                let rightX = w * (1.0 - 0.18)
                Path { path in
                    path.move(to: CGPoint(x: rightX, y: topH))
                    path.addLine(to: CGPoint(x: rightX, y: bottomY))
                }
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                .foregroundColor(Color.orange.opacity(0.8))
                
                // Center Crosshair
                Path { path in
                    // Horizontal center
                    path.move(to: CGPoint(x: (w / 2) - 16, y: h / 2))
                    path.addLine(to: CGPoint(x: (w / 2) + 16, y: h / 2))
                    // Vertical center
                    path.move(to: CGPoint(x: w / 2, y: (h / 2) - 16))
                    path.addLine(to: CGPoint(x: w / 2, y: (h / 2) + 16))
                }
                .stroke(Color.white.opacity(0.7), lineWidth: 1.5)
                
                // Text Labels for Guidance (can be toggled)
                if showLabels {
                    VStack {
                        // Top Label
                        HStack {
                            Text("▲ Верхняя зона UI (Поиск/Профиль)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.yellow)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(4)
                            Spacer()
                        }
                        .padding(.top, topH - 18)
                        .padding(.horizontal, 8)
                        
                        Spacer()
                        
                        // Right Column Label
                        HStack {
                            Spacer()
                            Text("▶ Кнопки (Лайк/Шеринг)")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(4)
                        }
                        .padding(.trailing, 6)
                        
                        Spacer()
                        
                        // Bottom Label
                        HStack {
                            Text("▼ Нижняя зона UI (Описание / Звук)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(4)
                            Spacer()
                        }
                        .padding(.bottom, (h * 0.22) - 18)
                        .padding(.horizontal, 8)
                    }
                }
                
                // Floating Top Drag & Control Bar
                VStack {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.portrait.split.2x1")
                            .foregroundColor(.cyan)
                            .font(.system(size: 11, weight: .bold))
                        
                        Text("9:16 Safe Areas")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                        
                        WindowDragArea()
                            .frame(height: 20)
                        
                        // Toggle labels
                        Button(action: { showLabels.toggle() }) {
                            Image(systemName: showLabels ? "text.bubble.fill" : "text.bubble")
                                .font(.system(size: 11))
                                .foregroundColor(showLabels ? .cyan : .white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                        .help("Скрыть/показать подписи зон")
                        
                        // Lock / Click-through toggle
                        Button(action: { manager.toggleLock() }) {
                            Image(systemName: manager.isLocked ? "lock.fill" : "lock.open")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(manager.isLocked ? .yellow : .white.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                        .help(manager.isLocked ? "Разблокировать (для перемещения)" : "Заблокировать (сквозной клик в DaVinci)")
                        
                        // Close button
                        Button(action: { manager.hide() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        .help("Закрыть сетку")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.top, 6)
                    
                    Spacer()
                }
            }
        }
    }
}
