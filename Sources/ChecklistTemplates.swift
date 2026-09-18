import Foundation
import SwiftUI

// MARK: - Checklist Template Model

struct ChecklistTemplate: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var items: [String]
    var isBuiltIn: Bool = false
}

// MARK: - Template Manager

final class TemplateManager: ObservableObject {
    static let shared = TemplateManager()
    
    @Published var customTemplates: [ChecklistTemplate] = []
    
    private let templatesFileURL: URL
    
    static let builtInTemplates: [ChecklistTemplate] = [
        ChecklistTemplate(
            name: "🎬 Предэкспортная проверка",
            items: [
                "Проверить уровни звука (-14 LUFS для YouTube / -16 для Reels)",
                "Проверить оффлайн клипы / Media Offline на таймлайне",
                "Проверить безопасные зоны 9:16 (Safe Areas)",
                "Проверить титры, плашки и опечатки в тексте",
                "Удалить неиспользуемые маркеры и мусор на таймлайне",
                "Проверить настройки рендера (Resolution, Codec, Audio channels)"
            ],
            isBuiltIn: true
        ),
        ChecklistTemplate(
            name: "🎨 Цветокоррекция (Color Grading)",
            items: [
                "Баланс белого и нормализация экспозиции на первом узле",
                "Матчинг шотов в сцене (Shot Matching)",
                "Skin tones: проверка тонов кожи по векторскопу",
                "Контраст и насыщенность (Curves / Primaries)",
                "Look / LUT / Творческая стилизация сцены",
                "Проверка клиппинга теней и светов (Scopes: Parade, Waveform)"
            ],
            isBuiltIn: true
        ),
        ChecklistTemplate(
            name: "✂️ Черновой монтаж (Rough Cut)",
            items: [
                "Отбор лучших дублей и синхронизация мультикама/звука",
                "Сборка смысловой структуры (A-Roll / диалоги)",
                "B-Roll перебивки, скриншоты и иллюстрации",
                "Черновая расстановка музыки и саунд-дизайна",
                "Проверка ритма и динамики монтажных склеек"
            ],
            isBuiltIn: true
        )
    ]
    
    var allTemplates: [ChecklistTemplate] {
        return Self.builtInTemplates + customTemplates
    }
    
    private init() {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = appSupport.appendingPathComponent("FloatNote", isDirectory: true)
        self.templatesFileURL = folder.appendingPathComponent("templates.json")
        loadCustomTemplates()
    }
    
    func loadCustomTemplates() {
        if let data = try? Data(contentsOf: templatesFileURL),
           let loaded = try? JSONDecoder().decode([ChecklistTemplate].self, from: data) {
            self.customTemplates = loaded
        }
    }
    
    func saveCustomTemplates() {
        if let data = try? JSONEncoder().encode(customTemplates) {
            try? data.write(to: templatesFileURL)
        }
    }
    
    func saveCurrentAsTemplate(name: String, items: [ChecklistItem]) {
        let textItems = items.map { $0.text }
        guard !textItems.isEmpty, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let newTemplate = ChecklistTemplate(name: name, items: textItems, isBuiltIn: false)
        customTemplates.append(newTemplate)
        saveCustomTemplates()
    }
    
    func deleteTemplate(id: UUID) {
        customTemplates.removeAll { $0.id == id }
        saveCustomTemplates()
    }
    
    func applyTemplate(_ template: ChecklistTemplate, replace: Bool = false) {
        let newItems = template.items.map { ChecklistItem(text: $0, isCompleted: false) }
        if replace {
            StorageManager.shared.items = newItems
        } else {
            StorageManager.shared.items.append(contentsOf: newItems)
        }
    }
}
