import SwiftUI
import AppKit

// MARK: - Aspect Ratio Mode Enum
enum AspectRatioMode: String, CaseIterable {
    case vertical = "9:16"
    case horizontal = "16:9"
}

// MARK: - Safe Areas Overlay Window & View

final class SafeAreasManager: ObservableObject {
    static let shared = SafeAreasManager()
    
    @Published var isVisible: Bool = false
    @Published var isLocked: Bool = false
    @Published var mode: AspectRatioMode = .vertical {
        didSet { updateAspectRatio() }
    }
    @Published var showCheatSheet: Bool = false
    
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
    
    func switchMode(_ newMode: AspectRatioMode) {
        self.mode = newMode
    }
    
    private func updateAspectRatio() {
        guard let panel = overlayPanel else { return }
        let currentFrame = panel.frame
        if mode == .vertical {
            panel.aspectRatio = NSSize(width: 9, height: 16)
            let newWidth = currentFrame.height * (9.0 / 16.0)
            panel.setFrame(NSRect(x: currentFrame.midX - (newWidth / 2.0), y: currentFrame.origin.y, width: newWidth, height: currentFrame.height), display: true, animate: true)
        } else {
            panel.aspectRatio = NSSize(width: 16, height: 9)
            let newHeight = currentFrame.width * (9.0 / 16.0)
            panel.setFrame(NSRect(x: currentFrame.origin.x, y: currentFrame.midY - (newHeight / 2.0), width: currentFrame.width, height: newHeight), display: true, animate: true)
        }
    }
    
    private func setupPanel() {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let height: CGFloat = min(screen.height * 0.72, 680)
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
        panel.minSize = NSSize(width: 200, height: 200)
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
                Color.black.opacity(0.03)
                
                // Outer Border
                Rectangle()
                    .stroke(manager.mode == .vertical ? Color.cyan.opacity(0.8) : Color.green.opacity(0.8), lineWidth: 2)
                
                if manager.mode == .vertical {
                    // VERTICAL 9:16 GUIDES
                    verticalGuides(w: w, h: h)
                } else {
                    // HORIZONTAL 16:9 GUIDES (Action Safe, Title Safe, Rule of Thirds)
                    horizontalGuides(w: w, h: h)
                }
                
                // Central Crosshair
                let cx = w / 2.0
                let cy = h / 2.0
                let crossSize: CGFloat = 16
                Path { path in
                    path.move(to: CGPoint(x: cx - crossSize, y: cy))
                    path.addLine(to: CGPoint(x: cx + crossSize, y: cy))
                    path.move(to: CGPoint(x: cx, y: cy - crossSize))
                    path.addLine(to: CGPoint(x: cx, y: cy + crossSize))
                }
                .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                
                // Cheat Sheet Popup
                if manager.showCheatSheet {
                    cheatSheetOverlay
                }
                
                // Top Control Toolbar
                VStack {
                    HStack(spacing: 6) {
                        // Aspect Ratio Toggle
                        Button(action: {
                            manager.mode = (manager.mode == .vertical) ? .horizontal : .vertical
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: manager.mode == .vertical ? "rectangle.portrait" : "rectangle")
                                    .font(.system(size: 10, weight: .bold))
                                Text(manager.mode.rawValue)
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(manager.mode == .vertical ? Color.cyan.opacity(0.3) : Color.green.opacity(0.3))
                            .cornerRadius(4)
                            .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        .help("Переключить соотношение 9:16 / 16:9")
                        
                        WindowDragArea()
                            .frame(height: 20)
                        
                        // Cheat Sheet button
                        Button(action: { manager.showCheatSheet.toggle() }) {
                            Image(systemName: "list.bullet.rectangle.portrait.fill")
                                .font(.system(size: 11))
                                .foregroundColor(manager.showCheatSheet ? .yellow : .white.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        .help("Шпаргалка спецификаций платформ (LUFS, битрейт, размеры)")
                        
                        // Toggle labels
                        Button(action: { showLabels.toggle() }) {
                            Image(systemName: showLabels ? "text.bubble.fill" : "text.bubble")
                                .font(.system(size: 11))
                                .foregroundColor(showLabels ? .cyan : .white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                        .help("Скрыть/показать подписи")
                        
                        // Lock toggle
                        Button(action: { manager.toggleLock() }) {
                            Image(systemName: manager.isLocked ? "lock.fill" : "lock.open")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(manager.isLocked ? .yellow : .white.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                        .help(manager.isLocked ? "Разблокировать" : "Заблокировать (сквозной клик)")
                        
                        // Close
                        Button(action: { manager.hide() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        .help("Закрыть оверлей")
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
    
    // MARK: - 9:16 Guides
    @ViewBuilder
    private func verticalGuides(w: CGFloat, h: CGFloat) -> some View {
        let topH = h * 0.14
        let bottomH = h * 0.22
        let rightW = w * 0.18
        
        Path { path in
            path.move(to: CGPoint(x: 0, y: topH))
            path.addLine(to: CGPoint(x: w, y: topH))
        }
        .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        .foregroundColor(Color.yellow.opacity(0.8))
        
        Path { path in
            path.move(to: CGPoint(x: 0, y: h - bottomH))
            path.addLine(to: CGPoint(x: w, y: h - bottomH))
        }
        .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        .foregroundColor(Color.red.opacity(0.8))
        
        Path { path in
            path.move(to: CGPoint(x: w - rightW, y: topH))
            path.addLine(to: CGPoint(x: w - rightW, y: h - bottomH))
        }
        .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        .foregroundColor(Color.orange.opacity(0.8))
        
        if showLabels {
            VStack {
                Text("▲ Верхняя зона (Шапка)")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(4)
                    .padding(.top, topH + 4)
                Spacer()
                Text("▼ Нижняя зона (Описание / Звук)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(4)
                    .padding(.bottom, bottomH + 4)
            }
        }
    }
    
    // MARK: - 16:9 Guides (Broadcast Action Safe & Title Safe + Thirds)
    @ViewBuilder
    private func horizontalGuides(w: CGFloat, h: CGFloat) -> some View {
        // Action Safe (93% - EBU/SMPTE)
        let asW = w * 0.035
        let asH = h * 0.035
        Rectangle()
            .stroke(Color.green.opacity(0.5), lineWidth: 1)
            .padding(.horizontal, asW)
            .padding(.vertical, asH)
        
        // Title Safe (90% / 80%)
        let tsW = w * 0.10
        let tsH = h * 0.10
        Rectangle()
            .stroke(Color.yellow.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
            .padding(.horizontal, tsW)
            .padding(.vertical, tsH)
        
        // Rule of Thirds
        Path { path in
            path.move(to: CGPoint(x: w / 3.0, y: 0))
            path.addLine(to: CGPoint(x: w / 3.0, y: h))
            path.move(to: CGPoint(x: (w * 2.0) / 3.0, y: 0))
            path.addLine(to: CGPoint(x: (w * 2.0) / 3.0, y: h))
            path.move(to: CGPoint(x: 0, y: h / 3.0))
            path.addLine(to: CGPoint(x: w, y: h / 3.0))
            path.move(to: CGPoint(x: 0, y: (h * 2.0) / 3.0))
            path.addLine(to: CGPoint(x: w, y: (h * 2.0) / 3.0))
        }
        .stroke(Color.white.opacity(0.2), lineWidth: 1)
        
        if showLabels {
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    Text("Action Safe (93%)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.green)
                    Text("Title Safe (80%)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.yellow)
                    Text("Правило третей")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.7))
                .cornerRadius(4)
                .padding(.bottom, 6)
            }
        }
    }
    
    // MARK: - Cheat Sheet Overlay
    private var cheatSheetOverlay: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("📊 Спецификации платформ")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { manager.showCheatSheet = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            Divider().background(Color.white.opacity(0.2))
            
            Group {
                specRow(platform: "YouTube 16:9", res: "3840x2160 / 1080p", lufs: "-14 LUFS", fps: "24-60 fps")
                specRow(platform: "Shorts / Reels", res: "1080x1920 (9:16)", lufs: "-14 LUFS", fps: "30 / 60 fps")
                specRow(platform: "TikTok", res: "1080x1920 (9:16)", lufs: "-14 LUFS", fps: "30 / 60 fps")
                specRow(platform: "Apple Podcasts", res: "Audio only", lufs: "-16 LUFS", fps: "-")
                specRow(platform: "ТВ / Broadcast", res: "EBU R128", lufs: "-23 LUFS", fps: "25 / 50 fps")
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.92))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .padding(20)
    }
    
    private func specRow(platform: String, res: String, lufs: String, fps: String) -> some View {
        HStack {
            Text(platform)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.cyan)
                .frame(width: 80, alignment: .leading)
            Text(res)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 90, alignment: .leading)
            Spacer()
            Text(lufs)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.yellow)
            Text(fps)
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}
