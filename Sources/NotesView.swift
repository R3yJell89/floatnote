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
                        Text(speech.isListening ? "Слушаю..." : "Диктовка")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(speech.isListening ? Color.red.opacity(0.3) : Color.white.opacity(0.08))
                    .foregroundColor(speech.isListening ? .red : .white.opacity(0.85))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help(speech.isListening ? "Остановить запись" : "Надиктовать речь в заметки")
                
                // Clipboard history toggle
                Button(action: {
                    clipboardPanel.toggle()
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 10))
                        Text("Буфер")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08))
                    .foregroundColor(.white.opacity(0.85))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Открыть историю буфера обмена")
                
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
                Text("\(storage.notesText.count) символов")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("Автосохранение")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.25))
        }
    }
}
