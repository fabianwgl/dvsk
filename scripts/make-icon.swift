// One-off icon generator: swift scripts/make-icon.swift <out.iconset dir>
// Then: iconutil -c icns <out.iconset> -o Resources/AppIcon.icns
import AppKit

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: make-icon.swift <out.iconset dir>\n".utf8))
    exit(1)
}
let outDir = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

// Draws the icon at an exact pixel size (macOS tile: 824/1024 of the canvas, transparent margin).
func render(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    defer { NSGraphicsContext.restoreGraphicsState() }

    let s = CGFloat(pixels)
    let tile = NSRect(x: s * 0.098, y: s * 0.098, width: s * 0.804, height: s * 0.804)
    let path = NSBezierPath(roundedRect: tile, xRadius: tile.width * 0.2237, yRadius: tile.width * 0.2237)

    // Dusk gradient: deep indigo (top) to amber (bottom)
    let gradient = NSGradient(colors: [
        NSColor(srgbRed: 0.10, green: 0.07, blue: 0.30, alpha: 1),
        NSColor(srgbRed: 0.42, green: 0.17, blue: 0.45, alpha: 1),
        NSColor(srgbRed: 0.93, green: 0.42, blue: 0.22, alpha: 1),
        NSColor(srgbRed: 1.00, green: 0.70, blue: 0.28, alpha: 1),
    ], atLocations: [0, 0.42, 0.78, 1], colorSpace: .sRGB)!
    gradient.draw(in: path, angle: -90)

    // White crescent moon: a disc minus an offset disc
    let r = tile.width * 0.27
    let center = NSPoint(x: tile.midX - r * 0.08, y: tile.midY + tile.height * 0.02)
    let moon = NSBezierPath(ovalIn: NSRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
    let bite = NSBezierPath(ovalIn: NSRect(
        x: center.x - r + r * 0.55, y: center.y - r + r * 0.40, width: r * 1.75, height: r * 1.75))
    // Fill the moon disc, clipped so the offset disc is cut away (no seam along the shared edge)
    let outside = NSBezierPath(rect: NSRect(x: 0, y: 0, width: s, height: s))
    outside.windingRule = .evenOdd
    outside.append(bite)
    NSGraphicsContext.saveGraphicsState()
    outside.addClip()
    NSColor.white.setFill()
    moon.fill()
    NSGraphicsContext.restoreGraphicsState()

    return rep.representation(using: .png, properties: [:])!
}

// Standard iconset: base size @1x and @2x
for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        try render(pixels: base * scale).write(to: URL(fileURLWithPath: "\(outDir)/\(name)"))
    }
}
print("Wrote iconset to \(outDir)")
