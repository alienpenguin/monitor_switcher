import AppKit

func generateIconSet() {
    let iconSizes: [(Int, Int)] = [
        (16, 1), (16, 2),
        (32, 1), (32, 2),
        (128, 1), (128, 2),
        (256, 1), (256, 2),
        (512, 1), (512, 2)
    ]

    let iconsetDir = "/tmp/MonitorSwitcher.iconset"
    let fileManager = FileManager.default
    try? fileManager.removeItem(atPath: iconsetDir)
    try? fileManager.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

    for (size, scale) in iconSizes {
        let pixelSize = size * scale
        let image = NSImage(size: NSSize(width: pixelSize, height: pixelSize))
        image.lockFocus()

        let bounds = NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize)

        // Background rounded rectangle
        let cornerRadius = CGFloat(pixelSize) * 0.22
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: CGFloat(pixelSize) * 0.04, dy: CGFloat(pixelSize) * 0.04), xRadius: cornerRadius, yRadius: cornerRadius)

        // Gradient background
        let gradient = NSGradient(
            starting: NSColor(red: 0.12, green: 0.38, blue: 0.95, alpha: 1.0),
            ending: NSColor(red: 0.45, green: 0.15, blue: 0.85, alpha: 1.0)
        )
        gradient?.draw(in: path, angle: 315)

        // Draw Left Monitor
        let m1Rect = NSRect(
            x: CGFloat(pixelSize) * 0.15,
            y: CGFloat(pixelSize) * 0.35,
            width: CGFloat(pixelSize) * 0.34,
            height: CGFloat(pixelSize) * 0.38
        )
        let m1Path = NSBezierPath(roundedRect: m1Rect, xRadius: CGFloat(pixelSize) * 0.04, yRadius: CGFloat(pixelSize) * 0.04)
        NSColor(white: 1.0, alpha: 0.9).setStroke()
        m1Path.lineWidth = max(1.5, CGFloat(pixelSize) * 0.035)
        m1Path.stroke()

        // Draw Right Monitor
        let m2Rect = NSRect(
            x: CGFloat(pixelSize) * 0.51,
            y: CGFloat(pixelSize) * 0.35,
            width: CGFloat(pixelSize) * 0.34,
            height: CGFloat(pixelSize) * 0.38
        )
        let m2Path = NSBezierPath(roundedRect: m2Rect, xRadius: CGFloat(pixelSize) * 0.04, yRadius: CGFloat(pixelSize) * 0.04)
        NSColor(white: 1.0, alpha: 0.9).setStroke()
        m2Path.lineWidth = max(1.5, CGFloat(pixelSize) * 0.035)
        m2Path.stroke()

        // Draw Switch Arrow between them
        let arrowY = CGFloat(pixelSize) * 0.54
        let arrowStart = CGFloat(pixelSize) * 0.38
        let arrowEnd = CGFloat(pixelSize) * 0.62

        let arrowPath = NSBezierPath()
        arrowPath.move(to: NSPoint(x: arrowStart, y: arrowY))
        arrowPath.line(to: NSPoint(x: arrowEnd, y: arrowY))
        arrowPath.lineWidth = max(2.0, CGFloat(pixelSize) * 0.045)
        arrowPath.lineCapStyle = .round
        NSColor(red: 0.3, green: 0.9, blue: 1.0, alpha: 1.0).setStroke()
        arrowPath.stroke()

        // Arrow head
        let headPath = NSBezierPath()
        let headSize = CGFloat(pixelSize) * 0.08
        headPath.move(to: NSPoint(x: arrowEnd - headSize, y: arrowY + headSize * 0.7))
        headPath.line(to: NSPoint(x: arrowEnd, y: arrowY))
        headPath.line(to: NSPoint(x: arrowEnd - headSize, y: arrowY - headSize * 0.7))
        headPath.lineWidth = max(2.0, CGFloat(pixelSize) * 0.045)
        headPath.lineCapStyle = .round
        headPath.lineJoinStyle = .round
        headPath.stroke()

        image.unlockFocus()

        // Save PNG
        if let tiff = image.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            let filename = scale == 1 ? "icon_\(size)x\(size).png" : "icon_\(size)x\(size)@2x.png"
            let filePath = "\(iconsetDir)/\(filename)"
            try? png.write(to: URL(fileURLWithPath: filePath))
        }
    }

    // Convert iconset to icns
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    task.arguments = ["-c", "icns", iconsetDir, "-o", "Resources/AppIcon.icns"]
    try? task.run()
    task.waitUntilExit()
}

generateIconSet()
