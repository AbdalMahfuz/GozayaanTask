import UIKit

protocol ImageLoading: Sendable {
    func loadImage(from url: URL) async -> UIImage?
}

/// An `actor` is inherently `Sendable`-safe, so the internal `NSCache` needs
/// no extra locking (spec 04 §5, D-31).
actor ImageLoader: ImageLoading {
    private let cache = NSCache<NSURL, UIImage>()
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func loadImage(from url: URL) async -> UIImage? {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }
        guard let (data, _) = try? await session.data(from: url), let image = UIImage(data: data) else {
            return nil
        }
        cache.setObject(image, forKey: url as NSURL)
        return image
    }
}
