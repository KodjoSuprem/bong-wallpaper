import Foundation

@MainActor
final class PreferencesStore {
    private enum Key {
        static let rotateDaily = "rotateDaily"
        static let currentIndex = "currentIndex"
        static let market = "market"
        static let lastAutoRotationDay = "lastAutoRotationDay"
    }

    private let defaults: UserDefaults
    private let dayFormatter: DateFormatter

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.dayFormatter = DateFormatter()
        self.dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        self.dayFormatter.dateFormat = "yyyy-MM-dd"
    }

    var rotateDaily: Bool {
        get { defaults.bool(forKey: Key.rotateDaily) }
        set { defaults.set(newValue, forKey: Key.rotateDaily) }
    }

    var currentIndex: Int {
        get { defaults.integer(forKey: Key.currentIndex) }
        set { defaults.set(newValue, forKey: Key.currentIndex) }
    }

    var market: String {
        get {
            if let value = defaults.string(forKey: Key.market), !value.isEmpty {
                return value
            }
            let computed = Self.defaultMarket()
            defaults.set(computed, forKey: Key.market)
            return computed
        }
        set {
            defaults.set(newValue, forKey: Key.market)
        }
    }

    var lastAutoRotationDay: String? {
        get { defaults.string(forKey: Key.lastAutoRotationDay) }
        set { defaults.set(newValue, forKey: Key.lastAutoRotationDay) }
    }

    func hasAutoRotatedToday(now: Date = Date()) -> Bool {
        lastAutoRotationDay == dayFormatter.string(from: now)
    }

    func markAutoRotatedToday(now: Date = Date()) {
        lastAutoRotationDay = dayFormatter.string(from: now)
    }

    private static func defaultMarket() -> String {
        let locale = Locale.autoupdatingCurrent
        let language = locale.language.languageCode?.identifier ?? "en"
        let region = locale.region?.identifier ?? "US"
        return "\(language)-\(region)"
    }
}
