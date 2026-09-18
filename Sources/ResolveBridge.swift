import Foundation
import AppKit

final class ResolveBridge: ObservableObject {
    static let shared = ResolveBridge()
    
    @Published var isConnected: Bool = false
    @Published var currentProject: String? = nil
    @Published var currentTimeline: String? = nil
    @Published var lastTimecode: String? = nil
    @Published var isQuerying: Bool = false
    
    private let scriptURL: URL
    
    private init() {
        // Look for script inside bundle resources, or fallback to current directory
        if let bundlePath = Bundle.main.path(forResource: "resolve_bridge", ofType: "py") {
            scriptURL = URL(fileURLWithPath: bundlePath)
        } else {
            let localSources = URL(fileURLWithPath: "/Users/r3yjell/Documents/Давинчи/FloatNote/Sources/resolve_bridge.py")
            if FileManager.default.fileExists(atPath: localSources.path) {
                scriptURL = localSources
            } else {
                scriptURL = URL(fileURLWithPath: "/Applications/FloatNote.app/Contents/Resources/resolve_bridge.py")
            }
        }
        
        checkConnection()
    }
    
    private func runPython(args: [String], completion: @escaping ([String: Any]?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            process.arguments = [self.scriptURL.path] + args
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe() // suppress stderr
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    DispatchQueue.main.async {
                        completion(json)
                    }
                    return
                }
            } catch {
                // Ignore process launch errors
            }
            
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
    
    func checkConnection() {
        runPython(args: ["info"]) { [weak self] json in
            guard let self = self else { return }
            if let json = json, let success = json["success"] as? Bool, success {
                self.isConnected = true
                self.currentProject = json["project"] as? String
                self.currentTimeline = json["timeline"] as? String
                self.lastTimecode = json["timecode"] as? String
            } else {
                self.isConnected = false
                self.currentProject = nil
                self.currentTimeline = nil
            }
        }
    }
    
    func fetchTimecode(completion: @escaping (String?) -> Void) {
        isQuerying = true
        runPython(args: ["get_tc"]) { [weak self] json in
            self?.isQuerying = false
            if let json = json, let success = json["success"] as? Bool, success,
               let tc = json["timecode"] as? String {
                self?.isConnected = true
                self?.lastTimecode = tc
                completion(tc)
            } else {
                completion(nil)
            }
        }
    }
    
    func jumpToTimecode(_ tc: String, completion: ((Bool) -> Void)? = nil) {
        let cleanTc = tc.trimmingCharacters(in: .whitespacesAndNewlines)
        runPython(args: ["jump", cleanTc]) { json in
            let success = (json?["success"] as? Bool) ?? false
            completion?(success)
        }
    }
    
    func addMarker(timecode: String, color: String = "Blue", name: String, note: String, completion: ((Bool) -> Void)? = nil) {
        let cleanTc = timecode.trimmingCharacters(in: .whitespacesAndNewlines)
        runPython(args: ["add_marker", cleanTc, color, name, note]) { json in
            let success = (json?["success"] as? Bool) ?? false
            completion?(success)
        }
    }
}
