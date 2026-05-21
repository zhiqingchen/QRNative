#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resourcesURL = root.appendingPathComponent("Resources", isDirectory: true)
let brandURL = root.appendingPathComponent("Assets/Brand", isDirectory: true)
let iconsetURL = resourcesURL.appendingPathComponent("QRNative.iconset", isDirectory: true)

try FileManager.default.createDirectory(at: resourcesURL, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: brandURL, withIntermediateDirectories: true)
try? FileManager.default.removeItem(at: iconsetURL)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

func drawIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let scale = CGFloat(size) / 1024
    context.scaleBy(x: scale, y: scale)

    let bounds = CGRect(x: 0, y: 0, width: 1024, height: 1024)
    context.clear(bounds)

    let background = NSBezierPath(roundedRect: CGRect(x: 128, y: 128, width: 768, height: 768), xRadius: 192, yRadius: 192)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.043, green: 0.063, blue: 0.125, alpha: 1),
        NSColor(red: 0.067, green: 0.110, blue: 0.196, alpha: 1),
        NSColor(red: 0.102, green: 0.176, blue: 0.322, alpha: 1)
    ])!
    gradient.draw(in: background, angle: -45)

    context.saveGState()
    background.addClip()

    let beam = NSBezierPath()
    beam.lineWidth = 34
    beam.lineCapStyle = .round
    beam.move(to: CGPoint(x: 336, y: 336))
    beam.line(to: CGPoint(x: 688, y: 688))
    NSColor(red: 0.918, green: 0.992, blue: 0.973, alpha: 0.72).setStroke()
    beam.stroke()
    context.restoreGState()

    func finder(_ x: CGFloat, _ y: CGFloat) {
        let path = NSBezierPath(roundedRect: CGRect(x: x, y: y, width: 150, height: 150), xRadius: 46, yRadius: 46)
        path.lineWidth = 38
        path.stroke()
    }

    NSColor(red: 0.918, green: 0.949, blue: 1.000, alpha: 1).setStroke()
    finder(300, 574)
    finder(574, 574)
    finder(300, 300)

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let data = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "QRNativeAssets", code: 1)
    }

    try data.write(to: url, options: [.atomic])
}

let iconFiles: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in iconFiles {
    try writePNG(drawIcon(size: size), to: iconsetURL.appendingPathComponent(name))
}

try writePNG(drawIcon(size: 512), to: brandURL.appendingPathComponent("qrnative-logo.png"))

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = [
    "-c", "icns",
    iconsetURL.path,
    "-o", resourcesURL.appendingPathComponent("QRNative.icns").path
]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    throw NSError(domain: "QRNativeAssets", code: Int(process.terminationStatus))
}

try? FileManager.default.removeItem(at: iconsetURL)
print("Generated Resources/QRNative.icns and Assets/Brand/qrnative-logo.png")
