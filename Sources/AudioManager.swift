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
    
    let audioFolderURL: URL       // Папка "Голосовые заметки"
    let sfxFolderURL: URL         // Папка "Звуковые эффекты" (SFX тоны, BEEP)
    let notesFolderURL: URL
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU")) ?? SFSpeechRecognizer()
    
    override init() {
        let baseDir = AppConstants.filesDirectory
        let voiceDir = baseDir.appendingPathComponent("Голосовые заметки", isDirectory: true)
        let sfxDir = baseDir.appendingPathComponent("Звуковые эффекты", isDirectory: true)
        let notesDir = baseDir.appendingPathComponent("Заметки", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: voiceDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: sfxDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: notesDir, withIntermediateDirectories: true)
        
        self.audioFolderURL = voiceDir
        self.sfxFolderURL = sfxDir
        self.notesFolderURL = notesDir
        super.init()
        Task { await loadAudioNotes() }
    }
    
    func loadAudioNotes() async {
        guard let files = try? FileManager.default.contentsOfDirectory(at: audioFolderURL, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles) else {
            return
        }
        
        let m4aFiles = files.filter { $0.pathExtension.lowercased() == "m4a" }
        
        var notes: [AudioNote] = []
        for url in m4aFiles {
            let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
            let date = attrs?[.creationDate] as? Date ?? Date()
            
            let asset = AVURLAsset(url: url)
            let durationSeconds: Double
            if #available(macOS 13.0, *) {
                durationSeconds = (try? await asset.load(.duration)).map { CMTimeGetSeconds($0) } ?? 0
            } else {
                durationSeconds = CMTimeGetSeconds(asset.duration)
            }
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
            Task { await self.loadAudioNotes() }
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
        Task { await loadAudioNotes() }
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
    
    // MARK: - SFX Generator (Censor Beep & Test Tones with selectable Frequency)
    func generateToneWav(frequency: Double = 1000.0) -> URL? {
        let freqInt = Int(frequency)
        let fileURL = sfxFolderURL.appendingPathComponent("FloatNote_Tone_\(freqInt)Hz.wav")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        }
        
        let sampleRate: Double = 44100.0
        let duration: Double = 1.0 // 1 second
        let totalSamples = Int(sampleRate * duration)
        
        var audioData = Data()
        // Generate 16-bit PCM Sine Wave at -18 dBFS (amplitude ~0.25)
        let amplitude: Double = 0.25 * Double(Int16.max)
        for i in 0..<totalSamples {
            let value = sin(2.0 * .pi * frequency * Double(i) / sampleRate) * amplitude
            var sample = Int16(value)
            withUnsafeBytes(of: &sample) { audioData.append(contentsOf: $0) }
        }
        
        // Build WAV Header
        var header = Data()
        header.append("RIFF".data(using: .ascii)!)
        var chunkSize = UInt32(36 + audioData.count)
        withUnsafeBytes(of: &chunkSize) { header.append(contentsOf: $0) }
        header.append("WAVEfmt ".data(using: .ascii)!)
        
        var subchunk1Size: UInt32 = 16
        var audioFormat: UInt16 = 1 // PCM
        var numChannels: UInt16 = 1 // Mono
        var sampleRateUInt32 = UInt32(sampleRate)
        var byteRate = UInt32(sampleRate * 1 * 2)
        var blockAlign: UInt16 = 2
        var bitsPerSample: UInt16 = 16
        
        withUnsafeBytes(of: &subchunk1Size) { header.append(contentsOf: $0) }
        withUnsafeBytes(of: &audioFormat) { header.append(contentsOf: $0) }
        withUnsafeBytes(of: &numChannels) { header.append(contentsOf: $0) }
        withUnsafeBytes(of: &sampleRateUInt32) { header.append(contentsOf: $0) }
        withUnsafeBytes(of: &byteRate) { header.append(contentsOf: $0) }
        withUnsafeBytes(of: &blockAlign) { header.append(contentsOf: $0) }
        withUnsafeBytes(of: &bitsPerSample) { header.append(contentsOf: $0) }
        
        header.append("data".data(using: .ascii)!)
        var subchunk2Size = UInt32(audioData.count)
        withUnsafeBytes(of: &subchunk2Size) { header.append(contentsOf: $0) }
        
        var fullWav = Data()
        fullWav.append(header)
        fullWav.append(audioData)
        
        do {
            try fullWav.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
    
    func playTone(frequency: Double = 1000.0) {
        if let url = generateToneWav(frequency: frequency) {
            play(url: url)
        }
    }
}
