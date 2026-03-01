import Foundation

struct DownloadResult {
    let catalog: [Wallpaper]
    let downloadedCount: Int
    let failedCount: Int
}

@MainActor
struct WallpaperService {
    let apiClient: BingAPIClient
    let cache: WallpaperCache
    let bundledProvider: BundledWallpaperProvider
    let downloader: ImageDownloader

    init(
        apiClient: BingAPIClient = BingAPIClient(),
        cache: WallpaperCache = WallpaperCache(),
        bundledProvider: BundledWallpaperProvider = BundledWallpaperProvider(),
        downloader: ImageDownloader = ImageDownloader()
    ) {
        self.apiClient = apiClient
        self.cache = cache
        self.bundledProvider = bundledProvider
        self.downloader = downloader
    }

    func loadCatalog() -> [Wallpaper] {
        let cached = cache.loadMetadata()
        let bundled = bundledProvider.load()
        return merge(cached: cached, bundled: bundled)
    }

    func refreshFromRemote(market: String, count: Int = 9) async throws -> DownloadResult {
        try cache.prepareDirectories()

        var cachedByID = Dictionary(uniqueKeysWithValues: cache.loadMetadata().map { ($0.id, $0) })
        let remotes = try await apiClient.fetchWallpapers(market: market, count: count)

        var downloadedCount = 0
        var failedCount = 0

        for remote in remotes {
            if cachedByID[remote.id] != nil {
                continue
            }

            do {
                let data = try await downloader.download(from: remote.imageURL)
                let wallpaper = try cache.store(remote: remote, data: data)
                cachedByID[wallpaper.id] = wallpaper
                downloadedCount += 1
            } catch {
                failedCount += 1
            }
        }

        let cached = sort(Array(cachedByID.values))
        try cache.saveMetadata(cached)

        let catalog = merge(cached: cached, bundled: bundledProvider.load())
        return DownloadResult(catalog: catalog, downloadedCount: downloadedCount, failedCount: failedCount)
    }

    private func merge(cached: [Wallpaper], bundled: [Wallpaper]) -> [Wallpaper] {
        var valuesByID = Dictionary(uniqueKeysWithValues: cached.map { ($0.id, $0) })
        for item in bundled where valuesByID[item.id] == nil {
            valuesByID[item.id] = item
        }
        return sort(Array(valuesByID.values))
    }

    private func sort(_ wallpapers: [Wallpaper]) -> [Wallpaper] {
        wallpapers.sorted { lhs, rhs in
            switch (lhs.publishedAt, rhs.publishedAt) {
            case let (l?, r?):
                if l != r { return l > r }
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                break
            }
            return lhs.id < rhs.id
        }
    }
}
