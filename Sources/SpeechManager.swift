import Foundation
import Speech
import AVFoundation

final class SpeechDictationManager: ObservableObject {
    static let shared = SpeechDictationManager()
    
    @Published var isListening: Bool = false
    @Published var liveTranscript: String = ""
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU")) ?? SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var onFinalResult: ((String) -> Void)?
    
    private init() {}
    
    func toggleDictation(onResult: @escaping (String) -> Void) {
        if isListening {
            stopDictation()
        } else {
            startDictation(onResult: onResult)
        }
    }
    
    func startDictation(onResult: @escaping (String) -> Void) {
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
