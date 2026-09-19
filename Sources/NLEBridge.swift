import Foundation
import AppKit

// MARK: - NLE Bridge & Timecode Utilities

struct NLEBridge {
    /// Extracts timecode string in HH:MM:SS:FF or HH:MM:SS;FF format
    static func extractTimecode(from text: String) -> String? {
        let pattern = #"\b(\d{2}:\d{2}:\d{2}[:;]\d{2})\b"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            return String(text[range])
        }
        return nil
    }
    
    /// Ensures the DaVinci Python bridge script is installed in DaVinci's Fusion Scripts Utility directory.
    @discardableResult
    static func ensureScriptInstalled() -> String {
        let utilityDir = NSString(string: "~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Utility").expandingTildeInPath
        let destPath = (utilityDir as NSString).appendingPathComponent("FloatNote_Bridge.py")
        
        let fm = FileManager.default
        if !fm.fileExists(atPath: destPath) {
            try? fm.createDirectory(atPath: utilityDir, withIntermediateDirectories: true)
            // Look for bundled script in Resources
            if let bundleScript = Bundle.main.path(forResource: "FloatNote_Bridge", ofType: "py") {
                try? fm.copyItem(atPath: bundleScript, toPath: destPath)
            }
        }
        return destPath
    }
    
    /// Resolve standard Python and DaVinci environment variables
    private static var daVinciEnvironment: [String: String] {
        var env = ProcessInfo.processInfo.environment
        env["RESOLVE_SCRIPT_API"] = "/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting"
        env["RESOLVE_SCRIPT_LIB"] = "/Applications/DaVinci Resolve/DaVinci Resolve.app/Contents/Libraries/Fusion/fusionscript.so"
        env["PYTHONPATH"] = "/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting/Modules"
        env["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        return env
    }
    
    /// Queries active playhead timecode from DaVinci Resolve or fallback clipboard
    static func fetchCurrentTimecode(completion: @escaping (String) -> Void) {
        let pb = NSPasteboard.general.string(forType: .string) ?? ""
        let tcPattern = #"(\d{2}:\d{2}:\d{2}[:;]\d{2})"#
        var fallbackTC = "01:00:00:00"
        if let range = pb.range(of: tcPattern, options: .regularExpression) {
            fallbackTC = String(pb[range])
        }
        
        let scriptPath = ensureScriptInstalled()
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            completion(fallbackTC)
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            proc.arguments = [scriptPath, "get_tc"]
            proc.environment = daVinciEnvironment
            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.standardError = Pipe()
            
            do {
                try proc.run()
                proc.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let liveTC = json["timecode"] as? String, !liveTC.isEmpty {
                    DispatchQueue.main.async {
                        completion(liveTC)
                    }
                    return
                }
            } catch {}
            
            DispatchQueue.main.async {
                completion(fallbackTC)
            }
        }
    }
    
    /// Jumps playhead to target timecode in configured NLE
    static func jumpToTimecode(_ tc: String, targetNLE: TargetNLE) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(tc, forType: .string)
        
        DispatchQueue.global(qos: .userInitiated).async {
            switch targetNLE {
            case .davinci:
                let scriptPath = ensureScriptInstalled()
                if FileManager.default.fileExists(atPath: scriptPath) {
                    let proc = Process()
                    proc.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
                    proc.arguments = [scriptPath, "jump", tc]
                    proc.environment = daVinciEnvironment
                    try? proc.run()
                    proc.waitUntilExit()
                }
            case .finalcut:
                let scriptSource = """
                tell application "Final Cut Pro" to activate
                tell application "System Events"
                    keystroke "p" using {control down}
                    delay 0.05
                    keystroke "v" using {command down}
                    key code 36
                end tell
                """
                if let appleScript = NSAppleScript(source: scriptSource) {
                    var error: NSDictionary?
                    appleScript.executeAndReturnError(&error)
                }
            case .premiere:
                let scriptSource = """
                tell application "Adobe Premiere Pro" to activate
                """
                if let appleScript = NSAppleScript(source: scriptSource) {
                    var error: NSDictionary?
                    appleScript.executeAndReturnError(&error)
                }
            }
        }
    }
    
    /// Cleans timecode and brackets from task text to produce a clean marker title
    static func cleanMarkerTitle(from text: String) -> String {
        var clean = text.replacingOccurrences(of: #"\[\d{2}:\d{2}:\d{2}[:;]\d{2}\]"#, with: "", options: .regularExpression)
        clean = clean.replacingOccurrences(of: #"\b\d{2}:\d{2}:\d{2}[:;]\d{2}\b"#, with: "", options: .regularExpression)
        clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("-") || clean.hasPrefix("—") || clean.hasPrefix(":") {
            clean = String(clean.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return clean.isEmpty ? "FloatNote Task" : clean
    }
    
    /// Adds a marker to the active timeline in DaVinci Resolve at the given timecode
    static func addMarkerToNLE(timecode: String, name: String, note: String = "FloatNote", color: String = "Blue", completion: ((Bool) -> Void)? = nil) {
        let scriptPath = ensureScriptInstalled()
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            completion?(false)
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            proc.arguments = [scriptPath, "marker", timecode, color, name, note]
            proc.environment = daVinciEnvironment
            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.standardError = Pipe()
            
            var success = false
            do {
                try proc.run()
                proc.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let ok = json["success"] as? Bool {
                    success = ok
                }
            } catch {}
            
            DispatchQueue.main.async {
                completion?(success)
            }
        }
    }
    
    /// Syncs all markers from active DaVinci Resolve timeline into FloatNote checklist
    static func syncMarkersFromDaVinci(completion: ((Bool, String) -> Void)? = nil) {
        let scriptPath = ensureScriptInstalled()
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            completion?(false, "Скрипт моста DaVinci не найден")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            proc.arguments = [scriptPath, "sync_markers"]
            proc.environment = daVinciEnvironment
            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.standardError = Pipe()
            
            do {
                try proc.run()
                proc.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                DispatchQueue.main.async {
                    // Reload checklist from file
                    StorageManager.shared.reloadChecklistFromFile()
                    completion?(true, output.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            } catch {
                DispatchQueue.main.async {
                    completion?(false, error.localizedDescription)
                }
            }
        }
    }
}

