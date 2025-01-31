import Foundation
import SwiftUI
import CloudKit
import OSLog

/// PosterImageCache is a service that manages the caching and loading of movie poster images.
/// It implements a three-tier caching strategy:
/// 1. Memory cache: For fast access to recently used images
/// 2. Disk cache: For persistent storage of images between app launches
/// 3. CloudKit/URL fallback: For loading images not in cache
///
/// The cache automatically manages memory usage and cleanup:
/// - Limits memory cache to 100 images
/// - Limits total memory usage to 50MB
/// - Automatically removes least recently used images
@MainActor
class PosterImageCache: ObservableObject {
    /// In-memory cache for quick access to recently used images
    private let cache = NSCache<NSString, UIImage>()
    
    /// FileManager for disk operations
    private let fileManager = FileManager.default
    
    /// Directory where cached images are stored on disk
    private let cacheDirectory: URL
    
    /// Logger for debugging and error tracking
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "PosterImageCache")
    
    /// Shared instance for app-wide caching
    static let shared = PosterImageCache()
    
    /// Private initializer to enforce singleton pattern
    /// Sets up cache configuration and creates cache directory if needed
    private init() {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("MoviePosters")
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Configure cache limits
        cache.countLimit = 100 // Maximum number of images in memory
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
    }
    
    /// Retrieves an image for a film, using the caching strategy
    /// - Parameter film: The film whose poster image to load
    /// - Returns: A SwiftUI Image if successful, nil otherwise
    /// - Note: This method follows this sequence:
    ///   1. Check memory cache
    ///   2. Check disk cache
    ///   3. Try loading from CloudKit asset
    ///   4. Download from URL
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
    
    /// Clears all cached images from both memory and disk
    /// Useful for troubleshooting or freeing up space
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    /// Downloads an image from a URL and creates a CloudKit asset
    /// - Parameter urlString: The URL of the image to download
    /// - Returns: A CKAsset if successful, nil otherwise
    /// - Throws: URLError if the URL is invalid or the download fails
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
