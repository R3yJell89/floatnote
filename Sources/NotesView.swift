import SwiftUI
import AppKit

// MARK: - Notes Tab View

struct NotesView: View {
    @ObservedObject var storage = StorageManager.shared
    @ObservedObject var clipboardPanel = ClipboardPanelManager.shared
    @ObservedObject var speech = SpeechDictationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Notes Toolbar
            HStack(spacing: 6) {
                // Timecode
                Button(action: {
                    NLEBridge.fetchCurrentTimecode { tc in
                        if storage.notesText.isEmpty {
                            storage.notesText = "[\(tc)] "
                        } else {
                            storage.notesText += "\n[\(tc)] "
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
                
                // Voice Dictation
                HStack(spacing: 0) {
                    Button(action: {
                        speech.toggleDictation { dictated in
                            if storage.notesText.isEmpty {
                                storage.notesText = dictated
                            } else {
                                storage.notesText += "\n" + dictated
                            }
                        }
                    }) {
                        HStack(spacing: 2) {
                            Image(systemName: speech.isListening ? "waveform" : "mic.fill")
                                .font(.system(size: 10))
                            Text(speech.isListening ? L10n.dictationListening : L10n.dictationBtn)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .padding(.leading, 6)
                        .padding(.trailing, 4)
                        .padding(.vertical, 3)
                        .background(speech.isListening ? Color.red.opacity(0.3) : Color.white.opacity(0.08))
                        .foregroundColor(speech.isListening ? .red : .white.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                    .help(speech.isListening ? (L10n.isRu ? "Остановить запись" : "Stop recording") : (L10n.isRu ? "Надиктовать речь в заметки" : "Dictate speech to notes"))
                    
                    // Dictation Locale Toggle
                    Button(action: {
                        if storage.preferences.dictationLanguage == "ru-RU" {
                            storage.preferences.dictationLanguage = "en-US"
                        } else {
                            storage.preferences.dictationLanguage = "ru-RU"
                        }
                    }) {
                        Text(storage.preferences.dictationLanguage == "ru-RU" ? "RU" : "EN")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 3)
                            .background(storage.preferences.dictationLanguage == "ru-RU" ? Color.blue.opacity(0.25) : Color.purple.opacity(0.25))
                            .foregroundColor(storage.preferences.dictationLanguage == "ru-RU" ? .cyan : .yellow)
                    }
                    .buttonStyle(.plain)
                    .help(L10n.isRu ? "Язык распознавания: \(storage.preferences.dictationLanguage == "ru-RU" ? "Русский" : "English") (нажмите для переключения)" : "Speech locale: \(storage.preferences.dictationLanguage == "ru-RU" ? "Russian" : "English") (click to switch)")
                }
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(speech.isListening ? Color.red.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 1)
                )
                
                // Clipboard history toggle
                Button(action: {
                    clipboardPanel.toggle()
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 10))
                        Text(L10n.clipboardBtn)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08))
                    .foregroundColor(.white.opacity(0.85))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help(L10n.isRu ? "Открыть историю буфера обмена" : "Open clipboard history")
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.2))
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            MacEditorView(text: $storage.notesText, fontSize: CGFloat(storage.preferences.fontSize))
                .padding(8)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack {
                Text("\(storage.notesText.count) \(L10n.charactersCount)")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text(L10n.autoSaved)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.25))
        }
    }
}
