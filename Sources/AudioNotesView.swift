import SwiftUI
import AppKit

// MARK: - Audio Notes View

struct AudioNotesView: View {
    @ObservedObject var audioManager = AudioManager.shared
    @State private var copiedNoteId: String?
    @State private var addedToNotesId: String?
    @State private var selectedFrequency: Double = 1000.0
    
    var body: some View {
        VStack(spacing: 0) {
            // Recording Controls Area
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    // Record / Stop Button
                    Button(action: {
                        if audioManager.isRecording {
                            audioManager.stopRecording()
                        } else {
                            audioManager.startRecording()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(audioManager.isRecording ? Color.red : Color.red.opacity(0.85))
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: audioManager.isRecording ? 2 : 0)
                                    )
                            Text(audioManager.isRecording ? "Стоп" : "Запись голоса")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(audioManager.isRecording ? Color.red.opacity(0.3) : Color.white.opacity(0.12))
                        .cornerRadius(7)
                    }
                    .buttonStyle(.plain)
                    
                    if audioManager.isRecording {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text(formatTime(audioManager.recordingDuration))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.red)
                        }
                    } else {
                        Text("\(audioManager.audioNotes.count) записей")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        NSWorkspace.shared.open(audioManager.audioFolderURL)
                    }) {
                        Image(systemName: "folder")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 26, height: 26)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                    .help("Открыть папку Аудио в Finder")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .background(Color.black.opacity(0.3))
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Audio List
            if audioManager.audioNotes.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "mic.slash")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.3))
                    Text("Нет голосовых записей")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Text("Нажмите «Запись голоса» для создания заметок")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.35))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(audioManager.audioNotes) { note in
                            audioNoteRow(note: note)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
            }
            
            // SFX & Audio Utilities Bar (Multi-Frequency Tone Generator)
            VStack(spacing: 5) {
                Divider().background(Color.white.opacity(0.12))
                
                HStack(spacing: 5) {
                    Image(systemName: "waveform")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.yellow)
                    
                    // Frequency Selector
                    Picker("", selection: $selectedFrequency) {
                        Text("440Hz").tag(440.0)
                        Text("800Hz").tag(800.0)
                        Text("1kHz").tag(1000.0)
                        Text("2kHz").tag(2000.0)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 155)
                    .controlSize(.mini)
                    
                    Spacer()
                    
                    // Play test tone
                    Button(action: {
                        audioManager.playTone(frequency: selectedFrequency)
                    }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 10))
                            .frame(width: 24, height: 20)
                            .background(Color.yellow.opacity(0.2))
                            .foregroundColor(.yellow)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .help("Прослушать тон \(Int(selectedFrequency)) Гц")
                    
                    // Drag-and-drop WAV badge
                    if let url = audioManager.generateToneWav(frequency: selectedFrequency) {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.up.right.and.arrow.down.left.rectangle")
                                .font(.system(size: 8))
                            Text("WAV")
                                .font(.system(size: 10, weight: .heavy))
                        }
                        .padding(.horizontal, 6)
                        .frame(height: 20)
                        .background(Color.yellow.opacity(0.25))
                        .foregroundColor(.yellow)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.yellow.opacity(0.6), lineWidth: 1)
                        )
                        .onDrag {
                            NSItemProvider(contentsOf: url) ?? NSItemProvider()
                        }
                        .help("Перетащите мышкой прямо на аудиодорожку в DaVinci, Premiere или FCPX!")
                        
                        // Finder reveal (direct via Process 'open -R')
                        Button(action: {
                            let proc = Process()
                            proc.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                            proc.arguments = ["-R", url.path]
                            try? proc.run()
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.08))
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(width: 24, height: 20)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help("Показать файл тона в Finder")
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.35))
            }
        }
    }
    
    private func audioNoteRow(note: AudioNote) -> some View {
        let isCurrentlyPlaying = audioManager.isPlaying && audioManager.currentlyPlayingURL == note.url
        
        return VStack(alignment: .leading, spacing: 6) {
            // Player Controls Row
            HStack(spacing: 8) {
                Button(action: {
                    audioManager.play(url: note.url)
                }) {
                    ZStack {
                        Color.white.opacity(0.001)
                        Image(systemName: isCurrentlyPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(isCurrentlyPlaying ? .accentColor : .white.opacity(0.95))
                    }
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(note.durationString)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Re-transcribe if needed
                if note.transcript == nil && !note.isTranscribing {
                    Button(action: {
                        audioManager.transcribeAudio(url: note.url)
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.08))
                            Image(systemName: "waveform.badge.magnifyingglass")
                                .font(.system(size: 12))
                                .foregroundColor(.accentColor)
                        }
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .help("Распознать речь")
                }
                
                // Reveal in Finder
                Button(action: {
                    audioManager.revealInFinder(url: note.url)
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                        Image(systemName: "folder")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .help("Показать в Finder")
                
                // Delete
                Button(action: {
                    audioManager.delete(url: note.url)
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.85))
                    }
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .help("Удалить запись")
            }
            
            // Transcription Display & Actions
            if note.isTranscribing {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 14, height: 14)
                    Text("Распознавание речи...")
                        .font(.system(size: 10))
                        .italic()
                        .foregroundColor(.yellow.opacity(0.9))
                }
                .padding(.horizontal, 4)
            } else if let transcript = note.transcript, !transcript.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(transcript)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            audioManager.copyTranscriptToClipboard(text: transcript)
                            copiedNoteId = note.id
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                if copiedNoteId == note.id { copiedNoteId = nil }
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: copiedNoteId == note.id ? "checkmark" : "doc.on.doc")
                                Text(copiedNoteId == note.id ? "Скопировано!" : "Копировать")
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        
                        Button(action: {
                            audioManager.appendToNotes(text: transcript, title: note.name)
                            addedToNotesId = note.id
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                if addedToNotesId == note.id { addedToNotesId = nil }
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: addedToNotesId == note.id ? "checkmark" : "note.text.badge.plus")
                                Text(addedToNotesId == note.id ? "Добавлено!" : "В заметки")
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.green.opacity(0.9))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        
                        Spacer()
                    }
                    .padding(.top, 2)
                }
                .padding(6)
                .background(Color.white.opacity(0.06))
                .cornerRadius(6)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
        .cornerRadius(6)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        let mins = s / 60
        let secs = s % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
