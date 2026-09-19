import Foundation
import Speech
import AVFoundation

final class SpeechDictationManager: ObservableObject {
    static let shared = SpeechDictationManager()
    
    @Published var isListening: Bool = false
    @Published var liveTranscript: String = ""
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var onFinalResult: ((String) -> Void)?
    
    private init() {}
    
    func currentLocaleIdentifier() -> String {
        return StorageManager.shared.preferences.dictationLanguage
    }
    
    func toggleDictation(localeId: String? = nil, onResult: @escaping (String) -> Void) {
        if isListening {
            stopDictation()
        } else {
            startDictation(localeId: localeId, onResult: onResult)
        }
    }
    
    func startDictation(localeId: String? = nil, onResult: @escaping (String) -> Void) {
        let loc = localeId ?? currentLocaleIdentifier()
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: loc)) ?? SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
        self.onFinalResult = onResult
        self.liveTranscript = ""
        
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                guard status == .authorized else {
                    self?.isListening = false
                    return
                }
                self?.beginAudioRecording()
            }
        }
    }
    
    private func beginAudioRecording() {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
        } catch {
            isListening = false
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.liveTranscript = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || result?.isFinal == true {
                DispatchQueue.main.async {
                    self.finishDictation()
                }
            }
        }
    }
    
    func stopDictation() {
        finishDictation()
    }
    
    private func finishDictation() {
        guard isListening else { return }
        isListening = false
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        
        let text = liveTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            onFinalResult?(text)
        }
        liveTranscript = ""
    }
}
