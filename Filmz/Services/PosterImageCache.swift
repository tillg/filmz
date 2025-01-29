import Foundation
import SwiftUI
import CloudKit
import OSLog

@MainActor
class PosterImageCache: ObservableObject {
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "PosterImageCache")
    
    static let shared = PosterImageCache()
    
    private init() {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("MoviePosters")
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Configure cache limits
        cache.countLimit = 100 // Maximum number of images in memory
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
    }
    
    func image(for film: Film) async -> Image? {
        // Check memory cache first
        if let cachedImage = cache.object(forKey: film.id.uuidString as NSString) {
            return Image(uiImage: cachedImage)
        }
        
        // Then check disk cache
        let imageUrl = cacheDirectory.appendingPathComponent(film.id.uuidString)
        if let diskCachedImage = try? UIImage(data: Data(contentsOf: imageUrl)) {
            cache.setObject(diskCachedImage, forKey: film.id.uuidString as NSString)
            return Image(uiImage: diskCachedImage)
        }
        
        // If we have a CloudKit asset, try to load it
        if let asset = film.posterAsset, let fileUrl = asset.fileURL {
            do {
                let imageData = try Data(contentsOf: fileUrl)
                if let uiImage = UIImage(data: imageData) {
                    // Save to both memory and disk cache
                    cache.setObject(uiImage, forKey: film.id.uuidString as NSString)
                    try imageData.write(to: imageUrl)
                    return Image(uiImage: uiImage)
                }
            } catch {
                logger.error("Failed to load image from CloudKit asset: \(error.localizedDescription)")
            }
        }
        
        // Finally, try to download from URL
        guard let url = URL(string: film.posterUrl) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                // Save to both memory and disk cache
                cache.setObject(uiImage, forKey: film.id.uuidString as NSString)
                try data.write(to: imageUrl)
                return Image(uiImage: uiImage)
            }
        } catch {
            logger.error("Failed to download image: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func downloadAndCreateAsset(from urlString: String) async throws -> CKAsset? {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Create a temporary file for the image
        let temporaryDirectory = fileManager.temporaryDirectory
        let temporaryFileURL = temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try data.write(to: temporaryFileURL)
        
        // Create CKAsset from the temporary file
        return CKAsset(fileURL: temporaryFileURL)
    }
}
