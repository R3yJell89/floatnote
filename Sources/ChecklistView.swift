import SwiftUI
import AppKit

// MARK: - Checklist Tab View

struct ChecklistView: View {
    @ObservedObject var storage = StorageManager.shared
    @ObservedObject var templateManager = TemplateManager.shared
    @ObservedObject var speech = SpeechDictationManager.shared
    
    @State private var newTaskText: String = ""
    @FocusState private var isNewTaskFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Checklist Actions & Templates Strip
            HStack(spacing: 6) {
                // Templates Menu
                Menu {
                    Section("Готовые шаблоны") {
                        ForEach(TemplateManager.builtInTemplates) { tmpl in
                            Menu(tmpl.name) {
                                Button("Добавить к текущим") {
                                    templateManager.applyTemplate(tmpl, replace: false)
                                }
                                Button("Заменить текущий список") {
                                    templateManager.applyTemplate(tmpl, replace: true)
                                }
                            }
                        }
                    }
                    if !templateManager.customTemplates.isEmpty {
                        Section("Мои шаблоны") {
                            ForEach(templateManager.customTemplates) { tmpl in
                                Menu(tmpl.name) {
                                    Button("Добавить к текущим") {
                                        templateManager.applyTemplate(tmpl, replace: false)
                                    }
                                    Button("Заменить текущий список") {
                                        templateManager.applyTemplate(tmpl, replace: true)
                                    }
                                    Divider()
                                    Button("🗑 Удалить шаблон", role: .destructive) {
                                        templateManager.deleteTemplate(id: tmpl.id)
                                    }
                                }
                            }
                        }
                    }
                    Divider()
                    Button("💾 Сохранить список как шаблон...") {
                        saveCurrentAsTemplatePrompt()
                    }
                    if !storage.items.isEmpty {
                        Divider()
                        Button("🧹 Очистить весь чеклист", role: .destructive) {
                            storage.items.removeAll()
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 10))
                        Text("Шаблоны")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(4)
                    .foregroundColor(.white.opacity(0.85))
                }
                .menuStyle(.borderlessButton)
                
                Spacer()
                
                // Quick Insert Timecode button
                Button(action: {
                    NLEBridge.fetchCurrentTimecode { tc in
                        if newTaskText.isEmpty {
                            newTaskText = "[\(tc)] "
                        } else {
                            newTaskText += " [\(tc)]"
                        }
                    }
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text("Таймкод")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.cyan.opacity(0.15))
                    .foregroundColor(.cyan)
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Вставить текущий таймкод плейхеда DaVinci (или из буфера)")
                
                // DaVinci Markers Sync button
                if storage.preferences.targetNLE == .davinci {
                    Button(action: {
                        NLEBridge.syncMarkersFromDaVinci { success, message in
                            // Completed sync
                        }
                    }) {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 10))
                            Text("Маркеры")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.purple.opacity(0.18))
                        .foregroundColor(.purple)
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .help("Импортировать все маркеры с текущего таймлайна DaVinci в чеклист")
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)
            .padding(.bottom, 2)
            
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach($storage.items) { $item in
                        checklistItemRow(item: $item)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Bottom Add & Status Bar
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 15))
                    
                    TextField(L10n.newTaskPlaceholder, text: $newTaskText)
                        .textFieldStyle(.plain)
                        .font(.system(size: storage.preferences.fontSize))
                        .foregroundColor(.white)
                        .focused($isNewTaskFocused)
                        .onSubmit {
                            addNewTask()
                        }
                    
                    // Voice dictation button
                    Button(action: {
                        speech.toggleDictation { dictatedText in
                            if self.newTaskText.isEmpty {
                                self.newTaskText = dictatedText
                            } else {
                                self.newTaskText += " " + dictatedText
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(speech.isListening ? Color.red.opacity(0.3) : Color.white.opacity(0.08))
                            Image(systemName: speech.isListening ? "waveform" : "mic.fill")
                                .font(.system(size: 10))
                                .foregroundColor(speech.isListening ? .red : .white.opacity(0.75))
                        }
                        .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                    .help(speech.isListening ? (L10n.isRu ? "Остановить запись голоса" : "Stop voice recording") : (L10n.isRu ? "Голосовой ввод задачи (\(storage.preferences.dictationLanguage == "ru-RU" ? "RU" : "EN"))" : "Voice input (\(storage.preferences.dictationLanguage == "ru-RU" ? "RU" : "EN"))"))
                    
                    if !newTaskText.isEmpty {
                        Button(action: addNewTask) {
                            Text(L10n.addBtn)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08))
                .cornerRadius(6)
                
                HStack {
                    let completedCount = storage.items.filter { $0.isCompleted }.count
                    Text(L10n.isRu ? "\(completedCount) из \(storage.items.count) выполнено" : "\(completedCount) of \(storage.items.count) completed")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Spacer()
                    
                    if completedCount > 0 {
                        Button(L10n.isRu ? "Очистить выполненные" : "Clear completed") {
                            storage.items.removeAll { $0.isCompleted }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(8)
            .background(Color.black.opacity(0.25))
        }
    }
    
    @State private var justMarkedId: UUID? = nil
    
    private func addNewTask() {
        let trimmed = newTaskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newItem = ChecklistItem(text: trimmed, isCompleted: false)
        storage.items.append(newItem)
        
        // Reverse Marker: if task contains a timecode and user is on DaVinci with autoCreateMarkers enabled
        if storage.preferences.targetNLE == .davinci && storage.preferences.autoCreateMarkers,
           let tc = NLEBridge.extractTimecode(from: trimmed) {
            let markerTitle = NLEBridge.cleanMarkerTitle(from: trimmed)
            NLEBridge.addMarkerToNLE(timecode: tc, name: markerTitle, note: "FloatNote Task", color: "Blue")
        }
        
        newTaskText = ""
        isNewTaskFocused = true
    }
    
    private func saveCurrentAsTemplatePrompt() {
        let alert = NSAlert()
        alert.messageText = "Сохранить чеклист как шаблон"
        alert.informativeText = "Введите название для нового шаблона:"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Сохранить")
        alert.addButton(withTitle: "Отмена")
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        input.placeholderString = "Мой шаблон монтажа"
        alert.accessoryView = input
        
        if alert.runModal() == .alertFirstButtonReturn {
            let name = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                templateManager.saveCurrentAsTemplate(name: name, items: storage.items)
            }
        }
    }
    
    private func checklistItemRow(item: Binding<ChecklistItem>) -> some View {
        let tc = NLEBridge.extractTimecode(from: item.wrappedValue.text)
        
        return HStack(alignment: .center, spacing: 6) {
            Button(action: {
                item.wrappedValue.isCompleted.toggle()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.001))
                    Image(systemName: item.wrappedValue.isCompleted ? "checkmark.square.fill" : "square")
                        .font(.system(size: max(16, CGFloat(storage.preferences.fontSize) + 2)))
                        .foregroundColor(item.wrappedValue.isCompleted ? .accentColor : .white.opacity(0.75))
                }
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            
            TextField("", text: item.text)
                .textFieldStyle(.plain)
                .font(.system(size: storage.preferences.fontSize))
                .foregroundColor(item.wrappedValue.isCompleted ? .white.opacity(0.4) : .white)
                .strikethrough(item.wrappedValue.isCompleted, color: .white.opacity(0.4))
            
            // Clickable Timecode Badge (Copies TC to clipboard & jumps active NLE playhead)
            if let tc = tc {
                Button(action: {
                    NLEBridge.jumpToTimecode(tc, targetNLE: storage.preferences.targetNLE)
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 8))
                        Text(tc)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.cyan.opacity(0.2))
                    .foregroundColor(.cyan)
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .help("Перейти к кадру \(tc) в монтажке и скопировать в буфер")
                
                // Add / Sync Marker Button to DaVinci Resolve
                if storage.preferences.targetNLE == .davinci {
                    Button(action: {
                        let markerTitle = NLEBridge.cleanMarkerTitle(from: item.wrappedValue.text)
                        NLEBridge.addMarkerToNLE(timecode: tc, name: markerTitle, note: "FloatNote: \(item.wrappedValue.text)", color: "Cyan") { ok in
                            if ok {
                                withAnimation {
                                    justMarkedId = item.wrappedValue.id
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                                    if justMarkedId == item.wrappedValue.id {
                                        withAnimation {
                                            justMarkedId = nil
                                        }
                                    }
                                }
                            }
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(justMarkedId == item.wrappedValue.id ? Color.green.opacity(0.3) : Color.white.opacity(0.08))
                            Image(systemName: justMarkedId == item.wrappedValue.id ? "checkmark" : "mappin.circle.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(justMarkedId == item.wrappedValue.id ? .green : .cyan)
                        }
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .help(justMarkedId == item.wrappedValue.id ? "Маркер установлен на таймлайн!" : "Поставить маркер на таймлайн DaVinci Resolve в точку \(tc)")
                }
            }
            
            Button(action: {
                if let idx = storage.items.firstIndex(where: { $0.id == item.wrappedValue.id }) {
                    storage.items.remove(at: idx)
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.001))
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.04))
        .cornerRadius(6)
    }
}
