import Foundation

enum WallpaperCacheError: Error {
    case cannotCreateDirectory
}

struct WallpaperCache {
    private let fileManager: FileManager
    private let appDirectoryName: String

    init(fileManager: FileManager = .default, appDirectoryName: String = "BongWallpaper") {
        self.fileManager = fileManager
        self.appDirectoryName = appDirectoryName
    }

    var appSupportDirectory: URL {
        let root = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return root.appendingPathComponent(appDirectoryName, isDirectory: true)
    }

    var wallpapersDirectory: URL {
        appSupportDirectory.appendingPathComponent("Wallpapers", isDirectory: true)
    }

    var metadataFileURL: URL {
        appSupportDirectory.appendingPathComponent("metadata.json", isDirectory: false)
    }

    func prepareDirectories() throws {
        try fileManager.createDirectory(at: appSupportDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: wallpapersDirectory, withIntermediateDirectories: true)
    }

    func loadMetadata() -> [Wallpaper] {
        guard fileManager.fileExists(atPath: metadataFileURL.path) else {
            return []
        }
        do {
            let data = try Data(contentsOf: metadataFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Wallpaper].self, from: data)
        } catch {
            return []
        }
    }

    func saveMetadata(_ wallpapers: [Wallpaper]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(wallpapers)
        try data.write(to: metadataFileURL, options: .atomic)
    }

    func store(remote: RemoteWallpaper, data: Data) throws -> Wallpaper {
        try prepareDirectories()

        let ext = fileExtension(from: remote.imageURL)
        let filename = "\(sanitize(remote.id)).\(ext)"
        let fileURL = wallpapersDirectory.appendingPathComponent(filename, isDirectory: false)

        if !fileManager.fileExists(atPath: fileURL.path) {
            try data.write(to: fileURL, options: .atomic)
        }

        return Wallpaper(
            id: remote.id,
            title: remote.title,
            imageURL: remote.imageURL,
            copyright: remote.copyright,
            publishedAt: remote.publishedAt,
            localFilePath: fileURL.path,
            source: .cache
        )
    }

    private func sanitize(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return value.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(scalar) : "_"
        }.reduce(into: "") { partial, character in
            partial.append(character)
        }
    }

    private func fileExtension(from url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        if ext.isEmpty {
            return "jpg"
        }
        return ext
    }
}
