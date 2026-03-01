import Foundation

@MainActor
final class MenuBarViewModel: ObservableObject {
    @Published var rotateDaily: Bool {
        didSet { preferences.rotateDaily = rotateDaily }
    }
    @Published private(set) var isDownloading = false
    @Published private(set) var statusMessage = "Starting..."
    @Published private(set) var currentTitle = "No wallpaper loaded"
    @Published private(set) var hasWallpapers = false

    private let service: WallpaperService
    private let applier: DesktopWallpaperApplier
    private let preferences: PreferencesStore
    private let scheduler: DailyRotationScheduler
    private let rotationPolicy: RotationPolicy

    private var catalog: [Wallpaper] = []
    private var started = false

    init(
        service: WallpaperService = WallpaperService(),
        applier: DesktopWallpaperApplier = DesktopWallpaperApplier(),
        preferences: PreferencesStore = PreferencesStore(),
        scheduler: DailyRotationScheduler = DailyRotationScheduler(),
        rotationPolicy: RotationPolicy = RotationPolicy()
    ) {
        self.service = service
        self.applier = applier
        self.preferences = preferences
        self.scheduler = scheduler
        self.rotationPolicy = rotationPolicy
        self.rotateDaily = preferences.rotateDaily
    }

    func start() {
        guard !started else { return }
        started = true

        reloadCatalogFromDisk()

        scheduler.start { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                await self.runAutoRotationIfNeeded(trigger: "scheduler")
            }
        }

        Task { @MainActor in
            await self.runAutoRotationIfNeeded(trigger: "startup")
        }
    }

    func previous() {
        guard !catalog.isEmpty else {
            statusMessage = "No wallpaper available"
            return
        }
        let current = normalizedIndex(preferences.currentIndex)
        let previousIndex = (current - 1 + catalog.count) % catalog.count
        applyWallpaper(at: previousIndex, markAutoRotation: false)
    }

    func next() {
        guard !catalog.isEmpty else {
            statusMessage = "No wallpaper available"
            return
        }
        let current = normalizedIndex(preferences.currentIndex)
        let nextIndex = (current + 1) % catalog.count
        applyWallpaper(at: nextIndex, markAutoRotation: false)
    }

    func download() {
        guard !isDownloading else { return }
        Task { @MainActor in
            await downloadInternal()
        }
    }

    private func reloadCatalogFromDisk() {
        catalog = service.loadCatalog()
        hasWallpapers = !catalog.isEmpty
        let index = normalizedIndex(preferences.currentIndex)
        if let wallpaper = catalog[safe: index] {
            currentTitle = wallpaper.title
            statusMessage = "Ready"
        } else {
            currentTitle = "No wallpaper loaded"
            statusMessage = "Use Download to fetch wallpapers"
        }
    }

    private func downloadInternal() async {
        isDownloading = true
        statusMessage = "Downloading from Bing..."
        defer { isDownloading = false }

        do {
            let result = try await service.refreshFromRemote(market: preferences.market, count: 9)
            catalog = result.catalog
            hasWallpapers = !catalog.isEmpty
            if catalog.isEmpty {
                currentTitle = "No wallpaper loaded"
                statusMessage = "Download finished but no valid wallpaper found"
                return
            }

            let current = normalizedIndex(preferences.currentIndex)
            currentTitle = catalog[current].title
            if result.failedCount == 0 {
                statusMessage = "Downloaded \(result.downloadedCount) new wallpapers"
            } else {
                statusMessage = "Downloaded \(result.downloadedCount), failed \(result.failedCount)"
            }
        } catch {
            reloadCatalogFromDisk()
            statusMessage = "Bing unavailable, using local cache"
        }
    }

    private func runAutoRotationIfNeeded(trigger: String) async {
        let shouldRotate = rotationPolicy.shouldAutoRotate(
            rotateDaily: rotateDaily,
            hasAutoRotatedToday: preferences.hasAutoRotatedToday()
        )
        guard shouldRotate else { return }

        await downloadInternal()
        guard !catalog.isEmpty else {
            statusMessage = "Auto-rotate skipped: no wallpaper available"
            return
        }

        let current = normalizedIndex(preferences.currentIndex)
        let nextIndex = (current + 1) % catalog.count
        applyWallpaper(at: nextIndex, markAutoRotation: true)
        statusMessage = "Auto-rotated (\(trigger))"
    }

    private func applyWallpaper(at index: Int, markAutoRotation: Bool) {
        guard let wallpaper = catalog[safe: index] else {
            statusMessage = "Wallpaper not found"
            return
        }

        do {
            try applier.apply(wallpaper)
            preferences.currentIndex = index
            if markAutoRotation {
                preferences.markAutoRotatedToday()
            }
            currentTitle = wallpaper.title
            if !markAutoRotation {
                statusMessage = "Applied: \(wallpaper.title)"
            }
        } catch {
            statusMessage = "Failed to apply wallpaper"
        }
    }

    private func normalizedIndex(_ index: Int) -> Int {
        guard !catalog.isEmpty else { return 0 }
        if index < 0 { return 0 }
        if index >= catalog.count { return 0 }
        return index
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
