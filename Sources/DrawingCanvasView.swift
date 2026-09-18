import SwiftUI
import AppKit

// MARK: - Drawing Tool Enum

enum DrawingTool: String, CaseIterable, Identifiable {
    case pen = "Карандаш"
    case line = "Линия"
    case arrow = "Стрелка"
    case rectangle = "Прямоугольник"
    case circle = "Овал"
    case eraser = "Ластик"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .pen: return "pencil"
        case .line: return "line.diagonal"
        case .arrow: return "arrow.up.right"
        case .rectangle: return "square"
        case .circle: return "circle"
        case .eraser: return "eraser"
        }
    }
}

// MARK: - Drawing Stroke Model

struct DrawingStroke: Identifiable {
    let id = UUID()
    var tool: DrawingTool
    var points: [CGPoint] = []
    var startPoint: CGPoint = .zero
    var endPoint: CGPoint = .zero
    var color: Color = .white
    var lineWidth: CGFloat = 4
    
    func makePath() -> Path {
        var path = Path()
        switch tool {
        case .pen, .eraser:
            guard points.count > 1 else { return path }
            path.addLines(points)
            
        case .line:
            path.move(to: startPoint)
            path.addLine(to: endPoint)
            
        case .rectangle:
            let rect = CGRect(
                x: min(startPoint.x, endPoint.x),
                y: min(startPoint.y, endPoint.y),
                width: max(1, abs(endPoint.x - startPoint.x)),
                height: max(1, abs(endPoint.y - startPoint.y))
            )
            path.addRect(rect)
            
        case .circle:
            let rect = CGRect(
                x: min(startPoint.x, endPoint.x),
                y: min(startPoint.y, endPoint.y),
                width: max(1, abs(endPoint.x - startPoint.x)),
                height: max(1, abs(endPoint.y - startPoint.y))
            )
            path.addEllipse(in: rect)
            
        case .arrow:
            path.move(to: startPoint)
            path.addLine(to: endPoint)
            
            let dx = endPoint.x - startPoint.x
            let dy = endPoint.y - startPoint.y
            let length = hypot(dx, dy)
            if length > 3 {
                let angle = atan2(dy, dx)
                let headLength = min(max(14, lineWidth * 3), length * 0.45)
                let arrowAngle = Double.pi / 6
                
                let p1 = CGPoint(
                    x: endPoint.x - headLength * CGFloat(cos(angle - arrowAngle)),
                    y: endPoint.y - headLength * CGFloat(sin(angle - arrowAngle))
                )
                let p2 = CGPoint(
                    x: endPoint.x - headLength * CGFloat(cos(angle + arrowAngle)),
                    y: endPoint.y - headLength * CGFloat(sin(angle + arrowAngle))
                )
                path.move(to: p1)
                path.addLine(to: endPoint)
                path.addLine(to: p2)
            }
        }
        return path
    }
}

// MARK: - Saved Sketch Model

struct SavedSketch: Identifiable {
    var id: String { url.path }
    let url: URL
    let name: String
    let image: NSImage?
}

// MARK: - Sketch Manager

final class SketchManager: ObservableObject {
    static let shared = SketchManager()
    
    @Published var savedSketches: [SavedSketch] = []
    let sketchesFolderURL: URL
    
    init() {
        let baseDir = URL(fileURLWithPath: "/Users/r3yjell/Documents/Давинчи/FloatNote_Files/Скетчи")
        try? FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
        self.sketchesFolderURL = baseDir
        loadSketches()
    }
    
    func loadSketches() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: sketchesFolderURL, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles) else {
            return
        }
        
        let pngFiles = files.filter { $0.pathExtension.lowercased() == "png" }
        
        var list: [SavedSketch] = []
        for url in pngFiles {
            let img = NSImage(contentsOf: url)
            list.append(SavedSketch(
                url: url,
                name: url.deletingPathExtension().lastPathComponent,
                image: img
            ))
        }
        
        self.savedSketches = list.reversed()
    }
    
    func saveCanvas(strokes: [DrawingStroke], size: CGSize, backgroundImage: NSImage? = nil) -> URL? {
        let width = size.width > 0 ? size.width : 380
        let height = size.height > 0 ? size.height : 360
        let actualSize = CGSize(width: width, height: height)
        
        guard !strokes.isEmpty || backgroundImage != nil else { return nil }
        
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(actualSize.width * 2),
            pixelsHigh: Int(actualSize.height * 2),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }
        
        rep.size = actualSize
        
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        
        let canvasBg = NSColor(calibratedRed: 0.1, green: 0.12, blue: 0.16, alpha: 1.0)
        canvasBg.setFill()
        NSRect(origin: .zero, size: actualSize).fill()
        
        if let bg = backgroundImage {
            bg.draw(in: NSRect(origin: .zero, size: actualSize))
        }
        
        func flipY(_ pt: CGPoint) -> NSPoint {
            return NSPoint(x: pt.x, y: actualSize.height - pt.y)
        }
        
        for stroke in strokes {
            let strokeColor = NSColor(stroke.color)
            
            switch stroke.tool {
            case .pen, .eraser:
                guard stroke.points.count > 1 else { continue }
                let path = NSBezierPath()
                path.lineWidth = stroke.lineWidth
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                path.move(to: flipY(stroke.points[0]))
                for i in 1..<stroke.points.count {
                    path.line(to: flipY(stroke.points[i]))
                }
                if stroke.tool == .eraser {
                    canvasBg.setStroke()
                } else {
                    strokeColor.setStroke()
                }
                path.stroke()
                
            case .line:
                let path = NSBezierPath()
                path.lineWidth = stroke.lineWidth
                path.lineCapStyle = .round
                path.move(to: flipY(stroke.startPoint))
                path.line(to: flipY(stroke.endPoint))
                strokeColor.setStroke()
                path.stroke()
                
            case .rectangle:
                let p1 = flipY(stroke.startPoint)
                let p2 = flipY(stroke.endPoint)
                let rect = NSRect(
                    x: min(p1.x, p2.x),
                    y: min(p1.y, p2.y),
                    width: max(1, abs(p2.x - p1.x)),
                    height: max(1, abs(p2.y - p1.y))
                )
                let path = NSBezierPath(rect: rect)
                path.lineWidth = stroke.lineWidth
                path.lineJoinStyle = .miter
                strokeColor.setStroke()
                path.stroke()
                
            case .circle:
                let p1 = flipY(stroke.startPoint)
                let p2 = flipY(stroke.endPoint)
                let rect = NSRect(
                    x: min(p1.x, p2.x),
                    y: min(p1.y, p2.y),
                    width: max(1, abs(p2.x - p1.x)),
                    height: max(1, abs(p2.y - p1.y))
                )
                let path = NSBezierPath(ovalIn: rect)
                path.lineWidth = stroke.lineWidth
                strokeColor.setStroke()
                path.stroke()
                
            case .arrow:
                let p1 = flipY(stroke.startPoint)
                let p2 = flipY(stroke.endPoint)
                let path = NSBezierPath()
                path.lineWidth = stroke.lineWidth
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                path.move(to: p1)
                path.line(to: p2)
                
                let dx = p2.x - p1.x
                let dy = p2.y - p1.y
                let length = hypot(dx, dy)
                if length > 3 {
                    let angle = atan2(dy, dx)
                    let headLength = min(max(14, stroke.lineWidth * 3), length * 0.45)
                    let arrowAngle = Double.pi / 6
                    
                    let a1 = NSPoint(
                        x: p2.x - headLength * CGFloat(cos(angle - arrowAngle)),
                        y: p2.y - headLength * CGFloat(sin(angle - arrowAngle))
                    )
                    let a2 = NSPoint(
                        x: p2.x - headLength * CGFloat(cos(angle + arrowAngle)),
                        y: p2.y - headLength * CGFloat(sin(angle + arrowAngle))
                    )
                    path.move(to: a1)
                    path.line(to: p2)
                    path.line(to: a2)
                }
                strokeColor.setStroke()
                path.stroke()
            }
        }
        
        NSGraphicsContext.restoreGraphicsState()
        
        guard let pngData = rep.representation(using: .png, properties: [:]) else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateStr = formatter.string(from: Date())
        let fileURL = sketchesFolderURL.appendingPathComponent("Скетч_\(dateStr).png")
        
        do {
            try pngData.write(to: fileURL)
            loadSketches()
            return fileURL
        } catch {
            print("Failed to save sketch: \(error)")
            return nil
        }
    }
    
    func deleteSketch(url: URL) {
        try? FileManager.default.removeItem(at: url)
        loadSketches()
    }
}

// MARK: - Drawing View

struct DrawingCanvasView: View {
    @ObservedObject var sketchManager = SketchManager.shared
    
    @State private var strokes: [DrawingStroke] = []
    @State private var currentStroke: DrawingStroke?
    
    @State private var currentTool: DrawingTool = .pen
    @State private var selectedColor: Color = .white
    @State private var lineWidth: CGFloat = 4
    @State private var canvasSize: CGSize = .zero
    @State private var saveMessage: String?
    
    @State private var backgroundImage: NSImage? = nil
    @State private var isCapturing: Bool = false
    
    let colors: [Color] = [.white, .red, .yellow, .cyan, .green, .orange]
    let widths: [(String, CGFloat)] = [("Тонкий", 3), ("Средний", 6), ("Маркер", 14)]
    
    var body: some View {
        VStack(spacing: 0) {
            // Responsive Two-Row Toolbar
            VStack(spacing: 4) {
                // Row 1: Shapes & Main Tools
                HStack(spacing: 4) {
                    ForEach(DrawingTool.allCases) { tool in
                        Button(action: {
                            currentTool = tool
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(currentTool == tool ? Color.white.opacity(0.24) : Color.white.opacity(0.06))
                                Image(systemName: tool.iconName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(currentTool == tool ? .yellow : .white.opacity(0.85))
                            }
                            .frame(width: 28, height: 26)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .help(tool.rawValue)
                    }
                    
                    Spacer()
                    
                    // Frame Grab (Screenshot area into canvas background)
                    Button(action: captureFrame) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(backgroundImage != nil ? Color.cyan.opacity(0.3) : Color.white.opacity(0.06))
                            Image(systemName: backgroundImage != nil ? "camera.fill" : "camera")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(backgroundImage != nil ? .cyan : .white.opacity(0.85))
                        }
                        .frame(width: 28, height: 26)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .help(backgroundImage != nil ? "Сделать новый снимок кадра (выделение области)" : "Снимок кадра DaVinci / экрана в холст")
                    
                    if backgroundImage != nil {
                        Button(action: { backgroundImage = nil }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.red.opacity(0.2))
                                Image(systemName: "photo.badge.minus")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red.opacity(0.9))
                            }
                            .frame(width: 28, height: 26)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .help("Удалить фоновый кадр")
                    }
                    
                    // Undo
                    Button(action: undoLastStroke) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.white.opacity(0.06))
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(strokes.isEmpty ? .white.opacity(0.25) : .white.opacity(0.85))
                        }
                        .frame(width: 28, height: 26)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .disabled(strokes.isEmpty)
                    .help("Отменить последнее действие (Cmd+Z)")
                    
                    // Clear
                    Button(action: { strokes.removeAll() }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.white.opacity(0.06))
                            Image(systemName: "trash")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(strokes.isEmpty ? .white.opacity(0.25) : .red.opacity(0.85))
                        }
                        .frame(width: 28, height: 26)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .disabled(strokes.isEmpty)
                    .help("Очистить холст")
                    
                    // Save PNG
                    Button(action: {
                        if let _ = sketchManager.saveCanvas(strokes: strokes, size: canvasSize, backgroundImage: backgroundImage) {
                            saveMessage = "Скетч сохранен!"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                saveMessage = nil
                            }
                        }
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "square.and.arrow.down.fill")
                                .font(.system(size: 11))
                            Text("PNG")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .fixedSize()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background((strokes.isEmpty && backgroundImage == nil) ? Color.gray.opacity(0.3) : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .disabled(strokes.isEmpty && backgroundImage == nil)
                }
                
                // Row 2: Colors & Brush Thickness
                HStack(spacing: 8) {
                    // Color dots with full-body hitboxes
                    HStack(spacing: 4) {
                        ForEach(colors, id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                                if currentTool == .eraser {
                                    currentTool = .pen
                                }
                            }) {
                                ZStack {
                                    Color.white.opacity(0.001)
                                    Circle()
                                        .fill(color)
                                        .frame(width: 16, height: 16)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: (selectedColor == color && currentTool != .eraser) ? 2 : 0)
                                        )
                                }
                                .frame(width: 24, height: 24)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                        }
                    }
                    
                    Divider()
                        .frame(height: 14)
                        .background(Color.white.opacity(0.2))
                    
                    // Thickness Picker Menu
                    Menu {
                        ForEach(widths, id: \.1) { name, w in
                            Button("\(name) (\(Int(w))px)") {
                                lineWidth = w
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: max(4, min(lineWidth, 10)), height: max(4, min(lineWidth, 10)))
                            Text("\(Int(lineWidth))px")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(4)
                        .contentShape(Rectangle())
                    }
                    .menuStyle(.borderlessButton)
                    .contentShape(Rectangle())
                    .help("Толщина линии")
                    
                    Spacer()
                    
                    // Current tool indicator
                    Text(currentTool.rawValue)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.35))
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Canvas Area
            GeometryReader { geo in
                ZStack {
                    Color.black.opacity(0.2)
                    
                    if let bg = backgroundImage {
                        Image(nsImage: bg)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    // Render existing strokes
                    Canvas { context, _ in
                        for stroke in strokes {
                            let path = stroke.makePath()
                            let color = stroke.tool == .eraser ? Color.black.opacity(0.25) : stroke.color
                            context.stroke(
                                path,
                                with: .color(color),
                                style: StrokeStyle(
                                    lineWidth: stroke.lineWidth,
                                    lineCap: .round,
                                    lineJoin: stroke.tool == .rectangle ? .miter : .round
                                )
                            )
                        }
                        
                        // Render stroke currently being drawn
                        if let current = currentStroke {
                            let path = current.makePath()
                            let color = current.tool == .eraser ? Color.black.opacity(0.25) : current.color
                            context.stroke(
                                path,
                                with: .color(color),
                                style: StrokeStyle(
                                    lineWidth: current.lineWidth,
                                    lineCap: .round,
                                    lineJoin: current.tool == .rectangle ? .miter : .round
                                )
                            )
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let pt = value.location
                                if currentStroke == nil {
                                    switch currentTool {
                                    case .pen, .eraser:
                                        currentStroke = DrawingStroke(
                                            tool: currentTool,
                                            points: [pt],
                                            startPoint: pt,
                                            endPoint: pt,
                                            color: selectedColor,
                                            lineWidth: lineWidth
                                        )
                                    case .line, .arrow, .rectangle, .circle:
                                        currentStroke = DrawingStroke(
                                            tool: currentTool,
                                            points: [pt],
                                            startPoint: pt,
                                            endPoint: pt,
                                            color: selectedColor,
                                            lineWidth: lineWidth
                                        )
                                    }
                                } else {
                                    switch currentTool {
                                    case .pen, .eraser:
                                        currentStroke?.points.append(pt)
                                    case .line, .arrow, .rectangle, .circle:
                                        currentStroke?.endPoint = pt
                                    }
                                }
                            }
                            .onEnded { _ in
                                if let finished = currentStroke {
                                    if finished.tool == .pen || finished.tool == .eraser {
                                        if finished.points.count > 1 {
                                            strokes.append(finished)
                                        }
                                    } else {
                                        let dist = hypot(finished.endPoint.x - finished.startPoint.x, finished.endPoint.y - finished.startPoint.y)
                                        if dist > 3 {
                                            strokes.append(finished)
                                        }
                                    }
                                }
                                currentStroke = nil
                            }
                    )
                    
                    // Notification Banner
                    if let msg = saveMessage {
                        VStack {
                            Text(msg)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(Color.green.opacity(0.85))
                                .cornerRadius(8)
                                .padding(.top, 10)
                            Spacer()
                        }
                    }
                }
                .onAppear {
                    canvasSize = geo.size
                }
                .onChange(of: geo.size) { newSize in
                    canvasSize = newSize
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .undoRequested)) { _ in
                undoLastStroke()
            }
            
            // Saved Sketches Strip
            if !sketchManager.savedSketches.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(sketchManager.savedSketches) { sketch in
                            HStack(spacing: 4) {
                                if let img = sketch.image {
                                    Image(nsImage: img)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 36, height: 26)
                                        .cornerRadius(4)
                                }
                                
                                Button(action: {
                                    NSWorkspace.shared.activateFileViewerSelecting([sketch.url])
                                }) {
                                    Image(systemName: "folder")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .buttonStyle(.plain)
                                .help("Показать в Finder")
                                
                                Button(action: {
                                    sketchManager.deleteSketch(url: sketch.url)
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(4)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .frame(height: 38)
                .background(Color.black.opacity(0.2))
            }
        }
    }
    
    private func undoLastStroke() {
        if !strokes.isEmpty {
            strokes.removeLast()
        }
    }
    
    private func captureFrame() {
        isCapturing = true
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = ["-i", "-c"]
            try? process.run()
            process.waitUntilExit()
            
            DispatchQueue.main.async {
                self.isCapturing = false
                if let image = NSImage(pasteboard: NSPasteboard.general) {
                    self.backgroundImage = image
                }
            }
        }
    }
}
