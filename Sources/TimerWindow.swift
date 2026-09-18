import SwiftUI
import AppKit

// MARK: - Timer Mode Enum

enum TimerMode: String, CaseIterable {
    case stopwatch = "Секундомер"
    case pomodoro = "Помодоро 25/5"
}

enum PomodoroPhase: String {
    case work = "Фокус (работа)"
    case rest = "Перерыв (отдых)"
}

// MARK: - Timer Manager

final class TimerManager: ObservableObject {
    static let shared = TimerManager()
    
    @Published var mode: TimerMode = .stopwatch {
        didSet { reset() }
    }
    
    @Published var isRunning: Bool = false
    @Published var secondsElapsed: Int = 0
    @Published var pomodoroRemaining: Int = 25 * 60
    @Published var pomodoroPhase: PomodoroPhase = .work
    @Published var completedPomodoros: Int = 0
    
    private var timer: Timer?
    
    private init() {}
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func toggle() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }
    
    func reset() {
        pause()
        secondsElapsed = 0
        if mode == .pomodoro {
            pomodoroPhase = .work
            pomodoroRemaining = 25 * 60
        }
    }
    
    private func tick() {
        switch mode {
        case .stopwatch:
            secondsElapsed += 1
            
        case .pomodoro:
            if pomodoroRemaining > 0 {
                pomodoroRemaining -= 1
            } else {
                // Switch phase
                if NSSound(named: "Glass")?.play() != true {
                    NSSound.beep()
                }
                if pomodoroPhase == .work {
                    pomodoroPhase = .rest
                    pomodoroRemaining = 5 * 60
                    completedPomodoros += 1
                } else {
                    pomodoroPhase = .work
                    pomodoroRemaining = 25 * 60
                }
            }
        }
    }
    
    var timeString: String {
        switch mode {
        case .stopwatch:
            let hours = secondsElapsed / 3600
            let minutes = (secondsElapsed % 3600) / 60
            let seconds = secondsElapsed % 60
            if hours > 0 {
                return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%02d:%02d", minutes, seconds)
            }
            
        case .pomodoro:
            let minutes = pomodoroRemaining / 60
            let seconds = pomodoroRemaining % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Timer Panel (Separate Window)

final class TimerPanelManager: ObservableObject {
    static let shared = TimerPanelManager()
    
    @Published var isVisible: Bool = false
    private var timerPanel: NSPanel?
    
    private init() {}
    
    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }
    
    func show() {
        if timerPanel == nil {
            setupPanel()
        }
        timerPanel?.orderFrontRegardless()
        isVisible = true
    }
    
    func hide() {
        timerPanel?.orderOut(nil)
        isVisible = false
    }
    
    private func setupPanel() {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 100, y: 100, width: 800, height: 600)
        let w: CGFloat = 260
        let h: CGFloat = 160
        let x = screen.maxX - w - 24
        let y = screen.minY + 60
        
        let panel = NSPanel(
            contentRect: NSRect(x: x, y: y, width: w, height: h),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.title = "Таймер монтажа"
        panel.isFloatingPanel = true
        panel.level = NSWindow.Level(rawValue: 1002)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isMovableByWindowBackground = true
        panel.minSize = NSSize(width: 220, height: 140)
        panel.maxSize = NSSize(width: 360, height: 220)
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isReleasedWhenClosed = false
        
        panel.contentView = FirstMouseHostingView(rootView: TimerView())
        self.timerPanel = panel
    }
}

// MARK: - Timer SwiftUI View

struct TimerView: View {
    @ObservedObject var timer = TimerManager.shared
    @ObservedObject var panelManager = TimerPanelManager.shared
    
    var body: some View {
        ZStack {
            // Background
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .opacity(0.92)
            Color.black.opacity(0.4)
            
            VStack(spacing: 8) {
                // Header Bar
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)
                    
                    Text(timer.mode.rawValue)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                    
                    // Close button
                    Button(action: {
                        panelManager.hide()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)
                
                // Mode Selector Switcher
                HStack(spacing: 4) {
                    ForEach(TimerMode.allCases, id: \.self) { m in
                        Button(action: {
                            timer.mode = m
                        }) {
                            Text(m.rawValue)
                                .font(.system(size: 10, weight: timer.mode == m ? .bold : .regular))
                                .foregroundColor(timer.mode == m ? .white : .white.opacity(0.6))
                                .padding(.vertical, 3)
                                .frame(maxWidth: .infinity)
                                .background(timer.mode == m ? Color.white.opacity(0.2) : Color.white.opacity(0.05))
                                .cornerRadius(5)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                
                // Digital Time Display
                VStack(spacing: 2) {
                    Text(timer.timeString)
                        .font(.system(size: 36, weight: .semibold, design: .monospaced))
                        .foregroundColor(timer.mode == .pomodoro && timer.pomodoroPhase == .rest ? .cyan : (timer.isRunning ? .green : .white))
                        .lineLimit(1)
                    
                    if timer.mode == .pomodoro {
                        Text("\(timer.pomodoroPhase.rawValue) • Сессий: \(timer.completedPomodoros)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }
                .padding(.vertical, 2)
                
                // Controls
                HStack(spacing: 12) {
                    // Reset Button
                    Button(action: {
                        timer.reset()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.12))
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .help("Сброс")
                    
                    // Play / Pause Button
                    Button(action: {
                        timer.toggle()
                    }) {
                        ZStack {
                            Circle()
                                .fill(timer.isRunning ? Color.orange.opacity(0.3) : Color.green.opacity(0.3))
                                .overlay(
                                    Circle()
                                        .stroke(timer.isRunning ? Color.orange : Color.green, lineWidth: 1.5)
                                )
                            Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .help(timer.isRunning ? "Пауза" : "Старт")
                }
                .padding(.bottom, 8)
            }
        }
    }
}
