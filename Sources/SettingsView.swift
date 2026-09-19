import SwiftUI
import Carbon

struct GreenModifierToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isOn ? Color(red: 0.18, green: 0.78, blue: 0.35) : Color.white.opacity(0.08))
                RoundedRectangle(cornerRadius: 6)
                    .stroke(configuration.isOn ? Color(red: 0.12, green: 0.88, blue: 0.4) : Color.white.opacity(0.18), lineWidth: 1.5)
                configuration.label
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(configuration.isOn ? .white : .secondary)
            }
            .frame(width: 38, height: 28)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

struct SettingsView: View {
    @ObservedObject var storage = StorageManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    // State for Window Toggle Hotkey
    @State private var windowKeyCode: UInt32 = 0
    @State private var windowCmd: Bool = false
    @State private var windowOpt: Bool = false
    @State private var windowCtrl: Bool = false
    @State private var windowShift: Bool = false
    
    // State for Ghost Toggle Hotkey
    @State private var ghostKeyCode: UInt32 = 0
    @State private var ghostCmd: Bool = false
    @State private var ghostOpt: Bool = false
    @State private var ghostCtrl: Bool = false
    @State private var ghostShift: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(Color(red: 0.18, green: 0.78, blue: 0.35))
                Text("Настройки FloatNote")
                    .font(.headline)
                Spacer()
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 2)
            
            Divider()
            
            // Target NLE Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Основной видеоредактор (NLE)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $storage.preferences.targetNLE) {
                    ForEach(TargetNLE.allCases) { nle in
                        Label(nle.rawValue, systemImage: nle.iconName).tag(nle)
                    }
                }
                .pickerStyle(.segmented)
                
                Text(nleDescription(for: storage.preferences.targetNLE))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if storage.preferences.targetNLE == .davinci {
                    Toggle("Автосоздание маркера в DaVinci при добавлении задачи", isOn: $storage.preferences.autoCreateMarkers)
                        .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.18, green: 0.78, blue: 0.35)))
                        .font(.caption)
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            
            // Window Behavior / Pinning Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Поведение окна")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Toggle("Закреплять окно поверх всех окон (Pin)", isOn: $storage.preferences.isPinned)
                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.18, green: 0.78, blue: 0.35)))
                    .modifier(OnChangePinnedModifier(value: storage.preferences.isPinned))
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            
            // Hotkeys Section
            VStack(alignment: .leading, spacing: 14) {
                Text("Глобальные горячие клавиши")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                // Toggle Window Hotkey
                VStack(alignment: .leading, spacing: 6) {
                    Text("Показать / скрыть окно:")
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Toggle("⌘", isOn: $windowCmd).toggleStyle(GreenModifierToggleStyle())
                        Toggle("⌥", isOn: $windowOpt).toggleStyle(GreenModifierToggleStyle())
                        Toggle("⌃", isOn: $windowCtrl).toggleStyle(GreenModifierToggleStyle())
                        Toggle("⇧", isOn: $windowShift).toggleStyle(GreenModifierToggleStyle())
                        
                        Picker("", selection: $windowKeyCode) {
                            ForEach(KeyOption.availableKeys) { key in
                                Text(key.title).tag(key.id)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 110)
                    }
                }
                
                // Toggle Ghost Mode Hotkey
                VStack(alignment: .leading, spacing: 6) {
                    Text("Сквозной клик (Ghost Mode):")
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Toggle("⌘", isOn: $ghostCmd).toggleStyle(GreenModifierToggleStyle())
                        Toggle("⌥", isOn: $ghostOpt).toggleStyle(GreenModifierToggleStyle())
                        Toggle("⌃", isOn: $ghostCtrl).toggleStyle(GreenModifierToggleStyle())
                        Toggle("⇧", isOn: $ghostShift).toggleStyle(GreenModifierToggleStyle())
                        
                        Picker("", selection: $ghostKeyCode) {
                            ForEach(KeyOption.availableKeys) { key in
                                Text(key.title).tag(key.id)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 110)
                    }
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            
            // Appearance Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Отображение")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Прозрачность:")
                        .font(.caption)
                    Slider(value: $storage.preferences.opacity, in: 0.2...1.0, step: 0.05)
                    Text("\(Int(storage.preferences.opacity * 100))%")
                        .font(.caption)
                        .monospacedDigit()
                        .frame(width: 40)
                }
                
                HStack {
                    Text("Размер шрифта:")
                        .font(.caption)
                    Slider(value: $storage.preferences.fontSize, in: 11...26, step: 1)
                    Text("\(Int(storage.preferences.fontSize)) пт")
                        .font(.caption)
                        .monospacedDigit()
                        .frame(width: 40)
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            
            Spacer()
            
            // Footer Buttons
            HStack {
                Button("По умолчанию") {
                    resetToDefaults()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(action: {
                    applySettings()
                    NotificationCenter.default.post(name: Notification.Name("closeSettings"), object: nil)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 0.18, green: 0.78, blue: 0.35))
                        Text("Сохранить")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 100, height: 30)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(18)
        .frame(width: 410, height: 490)
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    private func loadCurrentSettings() {
        let win = storage.preferences.toggleWindowHotkey
        windowKeyCode = win.carbonKeyCode
        windowCmd = (win.carbonModifiers & UInt32(cmdKey)) != 0
        windowOpt = (win.carbonModifiers & UInt32(optionKey)) != 0
        windowCtrl = (win.carbonModifiers & UInt32(controlKey)) != 0
        windowShift = (win.carbonModifiers & UInt32(shiftKey)) != 0
        
        let ghost = storage.preferences.toggleGhostHotkey
        ghostKeyCode = ghost.carbonKeyCode
        ghostCmd = (ghost.carbonModifiers & UInt32(cmdKey)) != 0
        ghostOpt = (ghost.carbonModifiers & UInt32(optionKey)) != 0
        ghostCtrl = (ghost.carbonModifiers & UInt32(controlKey)) != 0
        ghostShift = (ghost.carbonModifiers & UInt32(shiftKey)) != 0
    }
    
    private func applySettings() {
        // Build Window modifiers
        var winMods: UInt32 = 0
        if windowCmd { winMods |= UInt32(cmdKey) }
        if windowOpt { winMods |= UInt32(optionKey) }
        if windowCtrl { winMods |= UInt32(controlKey) }
        if windowShift { winMods |= UInt32(shiftKey) }
        if winMods == 0 { winMods = UInt32(optionKey) } // fallback
        
        let winConfig = HotkeyConfig(
            carbonKeyCode: windowKeyCode,
            carbonModifiers: winMods,
            displayString: HotkeyManager.formatHotkeyString(keyCode: windowKeyCode, modifiers: winMods)
        )
        
        // Build Ghost modifiers
        var gMods: UInt32 = 0
        if ghostCmd { gMods |= UInt32(cmdKey) }
        if ghostOpt { gMods |= UInt32(optionKey) }
        if ghostCtrl { gMods |= UInt32(controlKey) }
        if ghostShift { gMods |= UInt32(shiftKey) }
        if gMods == 0 { gMods = UInt32(optionKey) } // fallback
        
        let ghostConfig = HotkeyConfig(
            carbonKeyCode: ghostKeyCode,
            carbonModifiers: gMods,
            displayString: HotkeyManager.formatHotkeyString(keyCode: ghostKeyCode, modifiers: gMods)
        )
        
        storage.preferences.toggleWindowHotkey = winConfig
        storage.preferences.toggleGhostHotkey = ghostConfig
        
        // Register updated hotkeys
        HotkeyManager.shared.updateHotkeys(from: storage.preferences)
        
        // Update Menu Bar items with new hotkey display strings
        DispatchQueue.main.async {
            (NSApp.delegate as? AppDelegate)?.updateMenu()
        }
    }
    
    private func resetToDefaults() {
        storage.preferences.toggleWindowHotkey = .defaultToggleWindow
        storage.preferences.toggleGhostHotkey = .defaultToggleGhost
        storage.preferences.opacity = 0.92
        storage.preferences.fontSize = 14.0
        loadCurrentSettings()
        HotkeyManager.shared.updateHotkeys(from: storage.preferences)
        DispatchQueue.main.async {
            (NSApp.delegate as? AppDelegate)?.updateMenu()
        }
    }
    
    private func nleDescription(for nle: TargetNLE) -> String {
        switch nle {
        case .davinci:
            return "DaVinci Resolve: Live-опрос плейхеда, авто-прыжок по таймкодам и импорт маркеров через Python Bridge."
        case .premiere:
            return "Premiere Pro: Экспорт маркеров секвенса в чеклист через ExtendScript (FloatNote_Premiere.jsx)."
        case .finalcut:
            return "Final Cut Pro: Экспорт задач в FCPXML 1.10 с маркерами и авто-вставка таймкода по клику."
        }
    }
}

// MARK: - Compatibility modifier for onChange (macOS 13 / 14+)
private struct OnChangePinnedModifier: ViewModifier {
    let value: Bool
    func body(content: Content) -> some View {
        if #available(macOS 14.0, *) {
            content.onChange(of: value) { _, newValue in
                if let panel = NSApp.keyWindow as? FloatingPanel ?? NSApp.windows.first(where: { $0 is FloatingPanel }) as? FloatingPanel {
                    panel.setPinned(newValue)
                }
                (NSApp.delegate as? AppDelegate)?.updateMenu()
            }
        } else {
            content.onChange(of: value) { newValue in
                if let panel = NSApp.keyWindow as? FloatingPanel ?? NSApp.windows.first(where: { $0 is FloatingPanel }) as? FloatingPanel {
                    panel.setPinned(newValue)
                }
                (NSApp.delegate as? AppDelegate)?.updateMenu()
            }
        }
    }
}
