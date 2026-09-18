import Foundation
import AVFoundation
import AppKit
import Speech

struct AudioNote: Identifiable, Equatable {
    var id: String { url.path }
    let url: URL
    let name: String
    let creationDate: Date
    let durationString: String
    var transcript: String?
    var isTranscribing: Bool = false
}

final class AudioManager: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    static let shared = AudioManager()
    
    @Published var isRecording: Bool = false
    @Published var isPlaying: Bool = false
    @Published var currentlyPlayingURL: URL?
    @Published var recordingDuration: TimeInterval = 0
    @Published var audioNotes: [AudioNote] = []
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    
    let audioFolderURL: URL
    let notesFolderURL: URL
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU")) ?? SFSpeechRecognizer()
    
    override init() {
        let baseDir = URL(fileURLWithPath: "/Users/r3yjell/Documents/Давинчи/FloatNote_Files/Аудио")
        let notesDir = URL(fileURLWithPath: "/Users/r3yjell/Documents/Давинчи/FloatNote_Files/Заметки")
        try? FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: notesDir, withIntermediateDirectories: true)
        self.audioFolderURL = baseDir
        self.notesFolderURL = notesDir
        super.init()
        loadAudioNotes()
    }
    
    func loadAudioNotes() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: audioFolderURL, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles) else {
            return
        }
        
        let m4aFiles = files.filter { $0.pathExtension.lowercased() == "m4a" }
        
        var notes: [AudioNote] = []
        for url in m4aFiles {
            let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
            let date = attrs?[.creationDate] as? Date ?? Date()
            
            // Get duration
            let asset = AVURLAsset(url: url)
            let durationSeconds = CMTimeGetSeconds(asset.duration)
            let durationStr = formatDuration(durationSeconds)
            
            // Check for existing transcript file
            let txtURL = url.deletingPathExtension().appendingPathExtension("txt")
            let savedTranscript = try? String(contentsOf: txtURL, encoding: .utf8)
            
            notes.append(AudioNote(
                url: url,
                name: url.deletingPathExtension().lastPathComponent,
                creationDate: date,
                durationString: durationStr,
                transcript: savedTranscript,
                isTranscribing: false
            ))
        }
        
        // Sort newest first
        self.audioNotes = notes.sorted(by: { $0.creationDate > $1.creationDate })
    }
    
    func startRecording() {
        stopPlaying()
        
        // Request speech authorization if not yet asked
        SFSpeechRecognizer.requestAuthorization { _ in }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateStr = formatter.string(from: Date())
        let fileURL = audioFolderURL.appendingPathComponent("Запись_\(dateStr).m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            recordingDuration = 0
            
            recordingTimer?.invalidate()
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.recordingDuration += 1.0
            }
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        recordingTimer?.invalidate()
        recordingTimer = nil
        let recordedURL = audioRecorder?.url
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        recordingDuration = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.loadAudioNotes()
            if let url = recordedURL {
                self.transcribeAudio(url: url)
            }
        }
    }
    
    func transcribeAudio(url: URL) {
        if let idx = audioNotes.firstIndex(where: { $0.url == url }) {
            audioNotes[idx].isTranscribing = true
        }
        
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            guard status == .authorized else {
                DispatchQueue.main.async {
                    if let idx = self.audioNotes.firstIndex(where: { $0.url == url }) {
                        self.audioNotes[idx].isTranscribing = false
                    }
                }
                return
            }
            
            let recognizer = self.speechRecognizer ?? SFSpeechRecognizer()
            guard let recognizer = recognizer, recognizer.isAvailable else {
                DispatchQueue.main.async {
                    if let idx = self.audioNotes.firstIndex(where: { $0.url == url }) {
                        self.audioNotes[idx].isTranscribing = false
                    }
                }
                return
            }
            
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false
            
            recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result, result.isFinal {
                    let text = result.bestTranscription.formattedString
                    DispatchQueue.main.async {
                        self.saveTranscript(text: text, for: url)
                    }
                } else if let err = error {
                    print("Speech recognition error: \(err)")
                    DispatchQueue.main.async {
                        if let idx = self.audioNotes.firstIndex(where: { $0.url == url }) {
                            self.audioNotes[idx].isTranscribing = false
                        }
                    }
                }
            }
        }
    }
    
    private func saveTranscript(text: String, for audioURL: URL) {
        let baseName = audioURL.deletingPathExtension().lastPathComponent
        
        // Save .txt next to audio file
        let txtAudioURL = audioFolderURL.appendingPathComponent("\(baseName).txt")
        try? text.write(to: txtAudioURL, atomically: true, encoding: .utf8)
        
        // Also save copy into Notes folder
        let txtNotesURL = notesFolderURL.appendingPathComponent("\(baseName).txt")
        try? text.write(to: txtNotesURL, atomically: true, encoding: .utf8)
        
        if let idx = audioNotes.firstIndex(where: { $0.url == audioURL }) {
            audioNotes[idx].transcript = text
            audioNotes[idx].isTranscribing = false
        }
    }
    
    func play(url: URL) {
        if isPlaying && currentlyPlayingURL == url {
            stopPlaying()
            return
        }
        
        stopPlaying()
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
            currentlyPlayingURL = url
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
    
    func stopPlaying() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentlyPlayingURL = nil
    }
    
    func delete(url: URL) {
        if currentlyPlayingURL == url {
            stopPlaying()
        }
        try? FileManager.default.removeItem(at: url)
        let txtURL = url.deletingPathExtension().appendingPathExtension("txt")
        try? FileManager.default.removeItem(at: txtURL)
        loadAudioNotes()
    }
    
    func revealInFinder(url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    func copyTranscriptToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    func appendToNotes(text: String, title: String) {
        let entry = "\n\n🎙 [\(title)]:\n\(text)"
        StorageManager.shared.notesText += entry
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentlyPlayingURL = nil
        }
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "00:00" }
        let s = Int(seconds)
        let mins = s / 60
        let secs = s % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
