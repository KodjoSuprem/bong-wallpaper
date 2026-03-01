import Foundation

struct BundledWallpaperProvider {
    func load() -> [Wallpaper] {
        guard let bundledRoot = Bundle.module.resourceURL?.appendingPathComponent("BundledWallpapers", isDirectory: true),
              let items = try? FileManager.default.contentsOfDirectory(at: bundledRoot, includingPropertiesForKeys: nil)
        else {
            return []
        }

        let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "heic", "webp"]

        return items
            .filter { imageExtensions.contains($0.pathExtension.lowercased()) }
            .map { fileURL in
                let baseName = fileURL.deletingPathExtension().lastPathComponent
                let title = baseName
                    .replacingOccurrences(of: "_", with: " ")
                    .replacingOccurrences(of: "-", with: " ")

                return Wallpaper(
                    id: "bundled-\(baseName)",
                    title: title,
                    imageURL: nil,
                    copyright: nil,
                    publishedAt: nil,
                    localFilePath: fileURL.path,
                    source: .bundled
                )
            }
            .sorted { $0.id < $1.id }
    }
}
