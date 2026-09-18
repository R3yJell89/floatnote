import SwiftUI
import AppKit

// MARK: - Clipboard Item Model

struct ClipboardItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let content: String
    let timestamp: Date
    
    var preview: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 100 {
            return String(trimmed.prefix(100)) + "..."
        }
        return trimmed
    }
}

// MARK: - Clipboard Manager

final class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published var items: [ClipboardItem] = []
    @Published var searchQuery: String = ""
    @Published var copiedItemId: UUID? = nil
    
    private var lastChangeCount: Int = 0
    private var pollTimer: Timer?
    private let historyFileURL: URL
    
    var filteredItems: [ClipboardItem] {
        if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return items
        }
        return items.filter { $0.content.localizedCaseInsensitiveContains(searchQuery) }
    }
    
    private init() {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = appSupport.appendingPathComponent("FloatNote", isDirectory: true)
        self.historyFileURL = folder.appendingPathComponent("clipboard_history.json")
        
        loadHistory()
        lastChangeCount = NSPasteboard.general.changeCount
        startMonitoring()
    }
    
    private func startMonitoring() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { [weak self] _ in
            self?.checkForNewCopies()
        }
        RunLoop.main.add(pollTimer!, forMode: .common)
    }
    
    private func checkForNewCopies() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        guard let newString = pasteboard.string(forType: .string),
              !newString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // Avoid consecutive duplicate
        if let first = items.first, first.content == newString {
            return
        }
        
        let item = ClipboardItem(content: newString, timestamp: Date())
        items.insert(item, at: 0)
        
        // Keep up to 50 items
        if items.count > 50 {
            items = Array(items.prefix(50))
        }
        
        saveHistory()
    }
    
    func copyItem(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)
        lastChangeCount = pasteboard.changeCount
        
        copiedItemId = item.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            if self?.copiedItemId == item.id {
                self?.copiedItemId = nil
            }
        }
    }
    
    func deleteItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveHistory()
    }
    
    func clearAll() {
        items.removeAll()
        saveHistory()
    }
    
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: historyFileURL)
        }
    }
    
    private func loadHistory() {
        if let data = try? Data(contentsOf: historyFileURL),
           let loaded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            self.items = loaded
        }
    }
}

// MARK: - Clipboard Panel (Separate Window)

final class ClipboardPanelManager: ObservableObject {
    static let shared = ClipboardPanelManager()
    
    @Published var isVisible: Bool = false
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
    
    private func setupPanel() {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 100, y: 100, width: 800, height: 600)
        let w: CGFloat = 300
        let h: CGFloat = 380
        let x = screen.maxX - w - 24
        let y = screen.midY - (h / 2)
        
        let p = NSPanel(
            contentRect: NSRect(x: x, y: y, width: w, height: h),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        p.title = "Буфер обмена"
        p.isFloatingPanel = true
        p.level = NSWindow.Level(rawValue: 1002)
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        p.isMovableByWindowBackground = true
        p.minSize = NSSize(width: 240, height: 260)
        p.titlebarAppearsTransparent = true
        p.titleVisibility = .hidden
        p.isReleasedWhenClosed = false
        
        p.contentView = FirstMouseHostingView(rootView: ClipboardView())
        self.panel = p
    }
}

// MARK: - Clipboard SwiftUI View

struct ClipboardView: View {
    @ObservedObject var manager = ClipboardManager.shared
    @ObservedObject var panelManager = ClipboardPanelManager.shared
    
    var body: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .opacity(0.92)
            Color.black.opacity(0.35)
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.clipboard.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.cyan)
                    
                    Text("Буфер обмена")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if !manager.items.isEmpty {
                        Button(action: {
                            manager.clearAll()
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                        .help("Очистить историю")
                    }
                    
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
                .padding(.bottom, 6)
                
                // Search Bar
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                    
                    TextField("Поиск по буферу...", text: $manager.searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                    
                    if !manager.searchQuery.isEmpty {
                        Button(action: { manager.searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.08))
                .cornerRadius(6)
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
                
                Divider()
                    .background(Color.white.opacity(0.12))
                
                // Items List
                if manager.filteredItems.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "clipboard")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.2))
                        Text(manager.searchQuery.isEmpty ? "Буфер обмена пуст\nСкопируйте текст в любой программе" : "Ничего не найдено")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(manager.filteredItems) { item in
                                clipboardRow(item)
                            }
                        }
                        .padding(6)
                    }
                }
            }
        }
    }
    
    private func clipboardRow(_ item: ClipboardItem) -> some View {
        let isCopied = manager.copiedItemId == item.id
        
        return Button(action: {
            manager.copyItem(item)
        }) {
            HStack(alignment: .top, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.preview)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(timeAgo(item.timestamp))
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                Spacer()
                
                if isCopied {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                } else {
                    Button(action: {
                        manager.deleteItem(item)
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .help("Удалить")
                }
            }
            .padding(6)
            .background(isCopied ? Color.green.opacity(0.15) : Color.white.opacity(0.05))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isCopied ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .help("Нажмите, чтобы скопировать в буфер")
    }
    
    private func timeAgo(_ date: Date) -> String {
        let diff = Int(Date().timeIntervalSince(date))
        if diff < 60 { return "только что" }
        if diff < 3600 { return "\(diff / 60) мин назад" }
        if diff < 86400 { return "\(diff / 3600) ч назад" }
        let f = DateFormatter()
        f.dateFormat = "dd.MM HH:mm"
        return f.string(from: date)
    }
}
