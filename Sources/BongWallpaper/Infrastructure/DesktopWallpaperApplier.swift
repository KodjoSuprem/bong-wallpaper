import AppKit
import Foundation

enum WallpaperApplyError: Error {
    case fileNotFound
    case noScreenAvailable
}

@MainActor
final class DesktopWallpaperApplier {
    func apply(_ wallpaper: Wallpaper) throws {
        guard let fileURL = wallpaper.localFileURL,
              FileManager.default.fileExists(atPath: fileURL.path)
        else {
            throw WallpaperApplyError.fileNotFound
        }

        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            throw WallpaperApplyError.noScreenAvailable
        }

        try NSWorkspace.shared.setDesktopImageURL(fileURL, for: screen, options: [:])
    }
}
