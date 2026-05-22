#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resourcesURL = root.appendingPathComponent("Resources", isDirectory: true)
let brandURL = root.appendingPathComponent("Assets/Brand", isDirectory: true)
let sourceLogoURL = brandURL.appendingPathComponent("qrnative-logo-source.png")
let readmeLogoURL = brandURL.appendingPathComponent("qrnative-logo.png")
let iconsetURL = resourcesURL.appendingPathComponent("QRNative.iconset", isDirectory: true)

try FileManager.default.createDirectory(at: resourcesURL, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: brandURL, withIntermediateDirectories: true)
try? FileManager.default.removeItem(at: iconsetURL)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

guard FileManager.default.fileExists(atPath: sourceLogoURL.path) else {
    throw NSError(
        domain: "QRNativeAssets",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Missing source logo at \(sourceLogoURL.path)"]
    )
}

guard let sourceLogo = NSImage(contentsOf: sourceLogoURL) else {
    throw NSError(
        domain: "QRNativeAssets",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: "Unable to load source logo at \(sourceLogoURL.path)"]
    )
}

func pngData(size: Int) throws -> Data {
    guard
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: size,
            pixelsHigh: size,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bitmapFormat: [.alphaFirst],
            bytesPerRow: 0,
            bitsPerPixel: 0
        ),
        let context = NSGraphicsContext(bitmapImageRep: bitmap)
    else {
        throw NSError(domain: "QRNativeAssets", code: 1)
    }

    bitmap.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.cgContext.clear(CGRect(x: 0, y: 0, width: size, height: size))
    context.imageInterpolation = .high
    sourceLogo.draw(in: CGRect(x: 0, y: 0, width: size, height: size), from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "QRNativeAssets", code: 3)
    }

    return data
}

func writePNG(size: Int, to url: URL) throws {
    try pngData(size: size).write(to: url, options: [.atomic])
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
    try writePNG(size: size, to: iconsetURL.appendingPathComponent(name))
}

try writePNG(size: 1024, to: readmeLogoURL)

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
print("Generated Resources/QRNative.icns and Assets/Brand/qrnative-logo.png from Assets/Brand/qrnative-logo-source.png")
