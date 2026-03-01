import Foundation

enum ImageDownloadError: Error {
    case invalidStatusCode(Int)
}

struct ImageDownloader {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func download(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw ImageDownloadError.invalidStatusCode(httpResponse.statusCode)
        }
        return data
    }
}
