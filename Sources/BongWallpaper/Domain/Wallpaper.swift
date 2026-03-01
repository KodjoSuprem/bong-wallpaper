import Foundation

enum WallpaperSource: String, Codable {
    case bundled
    case cache
    case remote
}

struct Wallpaper: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let imageURL: URL?
    let copyright: String?
    let publishedAt: Date?
    let localFilePath: String?
    let source: WallpaperSource

    var localFileURL: URL? {
        guard let localFilePath else { return nil }
        return URL(fileURLWithPath: localFilePath)
    }
}

struct RemoteWallpaper: Hashable {
    let id: String
    let title: String
    let copyright: String?
    let publishedAt: Date?
    let imageURL: URL
}
