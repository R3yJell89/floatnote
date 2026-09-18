import Foundation
import Carbon
import AppKit

// MARK: - Key Definition Helper

struct KeyOption: Identifiable, Hashable {
    let id: UInt32 // Carbon KeyCode
    let title: String
    
    static let availableKeys: [KeyOption] = [
        KeyOption(id: UInt32(kVK_Space), title: "Space"),
        KeyOption(id: UInt32(kVK_ANSI_A), title: "A"),
        KeyOption(id: UInt32(kVK_ANSI_B), title: "B"),
        KeyOption(id: UInt32(kVK_ANSI_C), title: "C"),
        KeyOption(id: UInt32(kVK_ANSI_D), title: "D"),
        KeyOption(id: UInt32(kVK_ANSI_E), title: "E"),
        KeyOption(id: UInt32(kVK_ANSI_F), title: "F"),
        KeyOption(id: UInt32(kVK_ANSI_G), title: "G"),
        KeyOption(id: UInt32(kVK_ANSI_H), title: "H"),
        KeyOption(id: UInt32(kVK_ANSI_I), title: "I"),
        KeyOption(id: UInt32(kVK_ANSI_J), title: "J"),
        KeyOption(id: UInt32(kVK_ANSI_K), title: "K"),
        KeyOption(id: UInt32(kVK_ANSI_L), title: "L"),
        KeyOption(id: UInt32(kVK_ANSI_M), title: "M"),
        KeyOption(id: UInt32(kVK_ANSI_N), title: "N"),
        KeyOption(id: UInt32(kVK_ANSI_O), title: "O"),
        KeyOption(id: UInt32(kVK_ANSI_P), title: "P"),
        KeyOption(id: UInt32(kVK_ANSI_Q), title: "Q"),
        KeyOption(id: UInt32(kVK_ANSI_R), title: "R"),
        KeyOption(id: UInt32(kVK_ANSI_S), title: "S"),
        KeyOption(id: UInt32(kVK_ANSI_T), title: "T"),
        KeyOption(id: UInt32(kVK_ANSI_U), title: "U"),
        KeyOption(id: UInt32(kVK_ANSI_V), title: "V"),
        KeyOption(id: UInt32(kVK_ANSI_W), title: "W"),
        KeyOption(id: UInt32(kVK_ANSI_X), title: "X"),
        KeyOption(id: UInt32(kVK_ANSI_Y), title: "Y"),
        KeyOption(id: UInt32(kVK_ANSI_Z), title: "Z"),
        KeyOption(id: UInt32(kVK_ANSI_0), title: "0"),
        KeyOption(id: UInt32(kVK_ANSI_1), title: "1"),
        KeyOption(id: UInt32(kVK_ANSI_2), title: "2"),
        KeyOption(id: UInt32(kVK_ANSI_3), title: "3"),
        KeyOption(id: UInt32(kVK_ANSI_4), title: "4"),
        KeyOption(id: UInt32(kVK_ANSI_5), title: "5"),
        KeyOption(id: UInt32(kVK_ANSI_6), title: "6"),
        KeyOption(id: UInt32(kVK_ANSI_7), title: "7"),
        KeyOption(id: UInt32(kVK_ANSI_8), title: "8"),
        KeyOption(id: UInt32(kVK_ANSI_9), title: "9"),
        KeyOption(id: UInt32(kVK_Tab), title: "Tab"),
        KeyOption(id: UInt32(kVK_ANSI_Grave), title: "` (Tilde)"),
        KeyOption(id: UInt32(kVK_F1), title: "F1"),
        KeyOption(id: UInt32(kVK_F2), title: "F2"),
        KeyOption(id: UInt32(kVK_F3), title: "F3"),
        KeyOption(id: UInt32(kVK_F4), title: "F4"),
        KeyOption(id: UInt32(kVK_F5), title: "F5"),
        KeyOption(id: UInt32(kVK_F6), title: "F6")
    ]
    
    static func title(for keyCode: UInt32) -> String {
        availableKeys.first(where: { $0.id == keyCode })?.title ?? "Key (\(keyCode))"
    }
}

// MARK: - Hotkey Manager

final class HotkeyManager {
    static let shared = HotkeyManager()
    
    var onToggleWindow: (() -> Void)?
    var onToggleGhost: (() -> Void)?
    
    private var toggleWindowRef: EventHotKeyRef?
    private var toggleGhostRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    
    private init() {
        setupHandler()
    }
    
    private func setupHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let handler: EventHandlerUPP = { (_, event, _) -> OSStatus in
            guard let event = event else { return noErr }
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            if status == noErr {
                DispatchQueue.main.async {
                    HotkeyManager.shared.dispatch(id: hotKeyID.id)
                }
            }
            return noErr
        }
        
        InstallEventHandler(
            GetEventDispatcherTarget(),
            handler,
            1,
            &eventType,
            nil,
            &handlerRef
        )
    }
    
    func dispatch(id: UInt32) {
        if id == 1 {
            onToggleWindow?()
        } else if id == 2 {
            onToggleGhost?()
        }
    }
    
    func updateHotkeys(from prefs: AppPreferences) {
        // Unregister existing
        if let ref = toggleWindowRef {
            UnregisterEventHotKey(ref)
            toggleWindowRef = nil
        }
        if let ref = toggleGhostRef {
            UnregisterEventHotKey(ref)
            toggleGhostRef = nil
        }
        
        // Register Toggle Window Hotkey
        let id1 = EventHotKeyID(signature: OSType(0x464E5431), id: 1)
        RegisterEventHotKey(
            prefs.toggleWindowHotkey.carbonKeyCode,
            prefs.toggleWindowHotkey.carbonModifiers,
            id1,
            GetEventDispatcherTarget(),
            0,
            &toggleWindowRef
        )
        
        // Register Toggle Ghost Hotkey
        let id2 = EventHotKeyID(signature: OSType(0x464E5432), id: 2)
        RegisterEventHotKey(
            prefs.toggleGhostHotkey.carbonKeyCode,
            prefs.toggleGhostHotkey.carbonModifiers,
            id2,
            GetEventDispatcherTarget(),
            0,
            &toggleGhostRef
        )
    }
    
    static func formatHotkeyString(keyCode: UInt32, modifiers: UInt32) -> String {
        var parts: [String] = []
        if (modifiers & UInt32(controlKey)) != 0 { parts.append("⌃") }
        if (modifiers & UInt32(optionKey)) != 0 { parts.append("⌥") }
        if (modifiers & UInt32(shiftKey)) != 0 { parts.append("⇧") }
        if (modifiers & UInt32(cmdKey)) != 0 { parts.append("⌘") }
        parts.append(KeyOption.title(for: keyCode))
        return parts.joined(separator: " ")
    }
}
