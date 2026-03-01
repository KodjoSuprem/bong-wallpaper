import Foundation

enum BingAPIError: Error {
    case invalidResponse
    case invalidStatusCode(Int)
    case invalidPayload
}

struct BingAPIClient {
    private let session: URLSession
    private let baseURL = URL(string: "https://global.bing.com")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchWallpapers(market: String, count: Int = 9) async throws -> [RemoteWallpaper] {
        var components = URLComponents(url: baseURL.appendingPathComponent("HPImageArchive.aspx"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "format", value: "js"),
            URLQueryItem(name: "idx", value: "0"),
            URLQueryItem(name: "n", value: String(count)),
            URLQueryItem(name: "pid", value: "hp"),
            URLQueryItem(name: "FORM", value: "BEHPTB"),
            URLQueryItem(name: "uhd", value: "1"),
            URLQueryItem(name: "uhdwidth", value: "3840"),
            URLQueryItem(name: "uhdheight", value: "2160"),
            URLQueryItem(name: "setmkt", value: market),
            URLQueryItem(name: "setlang", value: "en")
        ]

        guard let url = components?.url else {
            throw BingAPIError.invalidPayload
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BingAPIError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw BingAPIError.invalidStatusCode(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(BingImageArchiveResponse.self, from: data)
        return decoded.images.compactMap { image in
            guard let imageURL = Self.makeImageURL(baseURL: baseURL, url: image.url, urlbase: image.urlbase) else {
                return nil
            }
            let startDate = Self.parse(dateString: image.startdate)
            let startKey = image.fullstartdate ?? image.startdate ?? "unknown"
            let urlKey = image.urlbase ?? image.url ?? UUID().uuidString
            let stableID = "\(startKey)-\(urlKey)"
            return RemoteWallpaper(
                id: stableID,
                title: image.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? image.title!.trimmingCharacters(in: .whitespacesAndNewlines) : "Bing Wallpaper",
                copyright: image.copyright,
                publishedAt: startDate,
                imageURL: imageURL
            )
        }
    }

    private static func parse(dateString: String?) -> Date? {
        guard let dateString, dateString.count >= 8 else { return nil }
        let value = String(dateString.prefix(8))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        return formatter.date(from: value)
    }

    private static func makeImageURL(baseURL: URL, url: String?, urlbase: String?) -> URL? {
        if let url, let absolute = URL(string: url, relativeTo: baseURL)?.absoluteURL {
            return absolute
        }
        if let urlbase {
            return URL(string: "\(baseURL.absoluteString)\(urlbase)_UHD.jpg")
        }
        return nil
    }
}

private struct BingImageArchiveResponse: Decodable {
    let images: [BingImage]
}

private struct BingImage: Decodable {
    let startdate: String?
    let fullstartdate: String?
    let title: String?
    let copyright: String?
    let url: String?
    let urlbase: String?
}
