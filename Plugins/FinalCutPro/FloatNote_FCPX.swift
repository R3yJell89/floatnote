import Foundation

/**
 * FloatNote Final Cut Pro (FCPXML) Generator
 * ==========================================
 * Позволяет экспортировать список задач с таймкодами из FloatNote
 * в валидный файл FCPXML (версия 1.10 / 1.11), который Final Cut Pro
 * импортирует через File -> Import -> XML с созданием маркеров на таймлайне.
 */

public struct FCPXMLGenerator {
    public static func generateFCPXML(from items: [(timecode: String, name: String, isCompleted: Bool)], fps: Double = 25.0) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.10">
            <resources>
                <format id="r1" name="FFVideoFormat1080p\(Int(fps))" frameDuration="100/\(Int(fps * 100))s" width="1920" height="1080"/>
            </resources>
            <library>
                <event name="FloatNote Markers">
                    <project name="FloatNote Tasks">
                        <sequence format="r1" duration="3600s">
                            <spine>
                                <gap name="Gap" duration="3600s" start="0s">
        """
        
        for item in items {
            let tc = item.timecode.replacingOccurrences(of: ";", with: ":")
            let parts = tc.split(separator: ":").compactMap { Double($0) }
            var startSeconds: Double = 0
            if parts.count == 4 {
                startSeconds = parts[0] * 3600 + parts[1] * 60 + parts[2] + (parts[3] / fps)
            }
            
            let completedMark = item.isCompleted ? "[DONE] " : ""
            let safeName = "\(completedMark)\(item.name)".replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "\"", with: "&quot;")
            
            xml += """
            
                                    <marker start="\(String(format: "%.3f", startSeconds))s" duration="1/\(Int(fps))s" value="\(safeName)" completed="\(item.isCompleted ? 1 : 0)"/>
            """
        }
        
        xml += """
        
                                </gap>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
        return xml
    }
}
