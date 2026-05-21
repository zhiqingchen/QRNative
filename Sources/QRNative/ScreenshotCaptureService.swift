import Foundation

enum ScreenshotCaptureError: LocalizedError {
    case launchFailed(String)
    case captureFailed(Int32)
    case unreadableImage

    var errorDescription: String? {
        switch self {
        case .launchFailed(let message):
            return "Unable to start screenshot capture: \(message)"
        case .captureFailed(let status):
            return "Screenshot capture failed with status \(status)."
        case .unreadableImage:
            return "Unable to read the screenshot."
        }
    }
}

struct ScreenshotCaptureService {
    func captureInteractivePNGData() async throws -> Data? {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("QRNative-screenshot-\(UUID().uuidString).png")

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = ["-i", "-t", "png", fileURL.path]

            process.terminationHandler = { process in
                defer {
                    try? FileManager.default.removeItem(at: fileURL)
                }

                guard process.terminationStatus == 0 else {
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        continuation.resume(throwing: ScreenshotCaptureError.captureFailed(process.terminationStatus))
                    } else {
                        continuation.resume(returning: nil)
                    }
                    return
                }

                do {
                    let data = try Data(contentsOf: fileURL)
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: ScreenshotCaptureError.unreadableImage)
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: ScreenshotCaptureError.launchFailed(error.localizedDescription))
            }
        }
    }
}
