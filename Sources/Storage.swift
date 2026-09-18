import Foundation
import SwiftUI
import AppKit

// MARK: - Models

struct ChecklistItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var text: String
    var isCompleted: Bool = false
}

struct HotkeyConfig: Codable, Equatable {
    var carbonKeyCode: UInt32
    var carbonModifiers: UInt32
    var displayString: String
    
    static let defaultToggleWindow = HotkeyConfig(
        carbonKeyCode: UInt32(0x31), // Space
        carbonModifiers: UInt32(0x0800), // optionKey
        displayString: "⌥ Space"
    )
    
    static let defaultToggleGhost = HotkeyConfig(
        carbonKeyCode: UInt32(0x05), // G
        carbonModifiers: UInt32(0x0800), // optionKey
        displayString: "⌥ G"
    )
}

enum TargetNLE: String, Codable, CaseIterable, Identifiable {
    case davinci = "DaVinci Resolve"
    case premiere = "Premiere Pro"
    case finalcut = "Final Cut Pro"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .davinci: return "dial.low.fill"
        case .premiere: return "film"
        case .finalcut: return "scissors"
        }
    }
}

struct AppPreferences: Codable {
    var opacity: Double = 0.92
    var fontSize: Double = 14.0
    var toggleWindowHotkey: HotkeyConfig = .defaultToggleWindow
    var toggleGhostHotkey: HotkeyConfig = .defaultToggleGhost
    var selectedTab: Int = 0 // 0: Checklist, 1: Notes, 2: Audio, 3: Sketch
    var windowX: Double? = nil
    var windowY: Double? = nil
    var windowWidth: Double = 380.0
    var windowHeight: Double = 480.0
    var isClickThrough: Bool = false
    var isPinned: Bool = true
    var targetNLE: TargetNLE = .davinci
    var autoCreateMarkers: Bool = true
    
    enum CodingKeys: String, CodingKey {
        case opacity, fontSize, toggleWindowHotkey, toggleGhostHotkey
        case selectedTab, windowX, windowY, windowWidth, windowHeight
        case isClickThrough, isPinned, targetNLE, autoCreateMarkers
    }
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        opacity = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 0.92
        fontSize = try container.decodeIfPresent(Double.self, forKey: .fontSize) ?? 14.0
        toggleWindowHotkey = try container.decodeIfPresent(HotkeyConfig.self, forKey: .toggleWindowHotkey) ?? .defaultToggleWindow
        toggleGhostHotkey = try container.decodeIfPresent(HotkeyConfig.self, forKey: .toggleGhostHotkey) ?? .defaultToggleGhost
        selectedTab = try container.decodeIfPresent(Int.self, forKey: .selectedTab) ?? 0
        windowX = try container.decodeIfPresent(Double.self, forKey: .windowX)
        windowY = try container.decodeIfPresent(Double.self, forKey: .windowY)
        windowWidth = try container.decodeIfPresent(Double.self, forKey: .windowWidth) ?? 380.0
        windowHeight = try container.decodeIfPresent(Double.self, forKey: .windowHeight) ?? 480.0
        isClickThrough = try container.decodeIfPresent(Bool.self, forKey: .isClickThrough) ?? false
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? true
        targetNLE = try container.decodeIfPresent(TargetNLE.self, forKey: .targetNLE) ?? .davinci
        autoCreateMarkers = try container.decodeIfPresent(Bool.self, forKey: .autoCreateMarkers) ?? true
    }
}

// MARK: - App Constants & Directory Paths

struct AppConstants {
    /// Shared user directory for exported notes, recordings, sound effects, and sketches
    static let filesDirectory: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let davinci = docs.appendingPathComponent("Давинчи", isDirectory: true)
        let base = davinci.appendingPathComponent("FloatNote_Files", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }()
}

// MARK: - Storage Manager

final class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    @Published var items: [ChecklistItem] = [] {
        didSet { saveItems() }
    }
    
    @Published var notesText: String = "" {
        didSet { saveNotes() }
    }
    
    @Published var preferences: AppPreferences = AppPreferences() {
        didSet { savePreferences() }
    }
    
    private let appSupportURL: URL
    private let itemsFileURL: URL
    private let notesFileURL: URL
    private let prefsFileURL: URL
    
    private init() {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        appSupportURL = appSupport.appendingPathComponent("FloatNote", isDirectory: true)
        
        try? fm.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        
        itemsFileURL = appSupportURL.appendingPathComponent("checklist.json")
        notesFileURL = appSupportURL.appendingPathComponent("notes.txt")
        prefsFileURL = appSupportURL.appendingPathComponent("preferences.json")
        
        loadAll()
        startWatchingChecklist()
    }
    
    private var fileWatcherSource: DispatchSourceFileSystemObject?
    private var isWritingInternally: Bool = false
    
    func startWatchingChecklist() {
        let fd = open(itemsFileURL.path, O_EVTONLY)
        guard fd >= 0 else { return }
        
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .attrib, .rename],
            queue: DispatchQueue.main
        )
        
        source.setEventHandler { [weak self] in
            guard let self = self else { return }
            if self.isWritingInternally { return }
            self.reloadChecklistFromFile()
        }
        
        source.setCancelHandler {
            close(fd)
        }
        
        source.resume()
        self.fileWatcherSource = source
    }
    
    func reloadChecklistFromFile() {
        guard let data = try? Data(contentsOf: itemsFileURL),
              let loadedItems = try? JSONDecoder().decode([ChecklistItem].self, from: data) else {
            return
        }
        if loadedItems != self.items {
            self.items = loadedItems
        }
    }
    
    func loadAll() {
        // Load Preferences
        if let data = try? Data(contentsOf: prefsFileURL),
           let loadedPrefs = try? JSONDecoder().decode(AppPreferences.self, from: data) {
            self.preferences = loadedPrefs
        }
        
        // Load Checklist
        if let data = try? Data(contentsOf: itemsFileURL),
           let loadedItems = try? JSONDecoder().decode([ChecklistItem].self, from: data) {
            self.items = loadedItems
        } else {
            // Default sample items
            self.items = [
                ChecklistItem(text: "Проверить звук и музыку", isCompleted: false),
                ChecklistItem(text: "Цветокоррекция основных планов", isCompleted: false),
                ChecklistItem(text: "Экспорт мастер-файла", isCompleted: false)
            ]
        }
        
        // Load Notes
        if let text = try? String(contentsOf: notesFileURL, encoding: .utf8) {
            self.notesText = text
        } else {
            self.notesText = "Заметки монтажа:\n• Таймкод хука 00:01:23\n• Перебивки с дрона на припеве\n• Титр: Имя Фамилия"
        }
    }
    
    private func saveItems() {
        isWritingInternally = true
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: itemsFileURL)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isWritingInternally = false
        }
    }
    
    private func saveNotes() {
        try? notesText.write(to: notesFileURL, atomically: true, encoding: .utf8)
    }
    
    private func savePreferences() {
        if let data = try? JSONEncoder().encode(preferences) {
            try? data.write(to: prefsFileURL)
        }
    }
}
