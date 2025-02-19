import Foundation
import SwiftUI
import CloudKit
import OSLog
import CryptoKit

/**
 ImageCache.swift
 ----------------

 The `ImageCache` class provides an asynchronous, multi-tier caching solution for images, identified by their URL. It is designed to optimize image retrieval by attempting to serve an image from the best available source, in the following order:

 1. **In-Memory Cache:**
    Uses `NSCache` for fast, temporary storage of recently accessed images.

 2. **Disk Cache:**
    Persists images to disk (using a SHA‑256 hash of the URL as the filename) so that images remain available across app launches.

 3. **CloudKit Asset (Optional):**
    If a CloudKit asset is provided, the cache will attempt to load the image from it if not already cached in memory or on disk.

 4. **Network Download:**
    If the image is not available in any cache, it is downloaded from its original URL, cached, and then returned.

 **Usage:**

 To fetch an image, simply call the asynchronous method `image(for:cloudKitAsset:)` on the shared instance of `ImageCache`, passing in the image's URL as a string. Optionally, you can also pass a `CKAsset` if one is available.

 **Example in SwiftUI:**

 ```swift
 import SwiftUI

 struct ContentView: View {
     @State private var loadedImage: Image?

     var body: some View {
         VStack {
             if let image = loadedImage {
                 image
                     .resizable()
                     .scaledToFit()
             } else {
                 Text("Loading image...")
             }
         }
         .task {
             // Replace with your image URL.
             let urlString = "https://example.com/image.jpg"
             
             // Fetch the image asynchronously. If you have a CloudKit asset, pass it as the second parameter.
             loadedImage = await ImageCache.shared.image(for: urlString)
         }
     }
 }
 **/


// MARK: - Helper Extension for Hashing a URL String
extension String {
    /// Returns a SHA‑256 hash of the string.
    func sha256() -> String {
        let inputData = Data(self.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}

@MainActor
class ImageCache: ObservableObject {
    /// In-memory cache for fast access to images.
    private let cache = NSCache<NSString, UIImage>()
    
    /// FileManager instance for disk operations.
    private let fileManager = FileManager.default
    
    /// Directory where cached images are stored.
    private let cacheDirectory: URL
    
    /// Logger for debugging and error tracking.
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.app", category: "ImageCache")
    
    /// Shared instance for app-wide caching.
    static let shared = ImageCache()
    
    /// Private initializer to enforce singleton pattern.
    private init() {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("CachedImages")
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Configure cache limits.
        cache.countLimit = 100 // Maximum number of images in memory.
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit.
    }
    
    /// Retrieves an image for the given URL.
    ///
    /// - Parameters:
    ///   - urlString: The URL string for the image.
    ///   - cloudKitAsset: Optionally, a CKAsset that may already contain the image.
    /// - Returns: A SwiftUI Image if successful, or nil otherwise.
    func image(for urlString: String, cloudKitAsset: CKAsset? = nil) async -> Image? {
        let key = urlString as NSString
        
        // 1. Check the in-memory cache.
        if let cachedImage = cache.object(forKey: key) {
            return Image(uiImage: cachedImage)
        }
        
        // 2. Check the disk cache.
        // Use the URL's SHA‑256 hash as the filename.
        let fileName = urlString.sha256()
        let fileUrl = cacheDirectory.appendingPathComponent(fileName)
        if let imageData = try? Data(contentsOf: fileUrl),
           let diskImage = UIImage(data: imageData) {
            cache.setObject(diskImage, forKey: key)
            return Image(uiImage: diskImage)
        }
        
        // 3. If a CloudKit asset is provided, try to load the image from it.
        if let asset = cloudKitAsset, let assetFileUrl = asset.fileURL {
            do {
                let assetData = try Data(contentsOf: assetFileUrl)
                if let assetImage = UIImage(data: assetData) {
                    cache.setObject(assetImage, forKey: key)
                    try? assetData.write(to: fileUrl)
                    return Image(uiImage: assetImage)
                }
            } catch {
                logger.error("Failed to load image from CloudKit asset: \(error.localizedDescription)")
            }
        }
        
        // 4. Download the image from its original URL.
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let downloadedImage = UIImage(data: data) {
                cache.setObject(downloadedImage, forKey: key)
                try? data.write(to: fileUrl)
                return Image(uiImage: downloadedImage)
            }
        } catch {
            logger.error("Failed to download image: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Clears all cached images from both memory and disk.
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    /// Downloads an image from a URL and creates a CloudKit asset.
    ///
    /// - Parameter urlString: The URL of the image to download.
    /// - Returns: A CKAsset if successful, or nil otherwise.
    /// - Throws: A URLError if the URL is invalid or the download fails.
    func downloadAndCreateAsset(from urlString: String) async throws -> CKAsset? {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Create a temporary file to store the image data.
        let temporaryFileURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try data.write(to: temporaryFileURL)
        
        return CKAsset(fileURL: temporaryFileURL)
    }
    
    /// Outputs debug information about the cache's status.
    func debugCacheInfo() {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            let totalSize = files.reduce(0) { (sum: Int, url: URL) -> Int in
                return ((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) + sum
            }
            logger.debug("""
                📁 Cache Directory: \(self.cacheDirectory.path)
                📊 Files in cache: \(files.count)
                💾 Total size: \(Double(totalSize) / 1_000_000.0) MB
                🧠 Memory cache limit: \(self.cache.totalCostLimit)
                """)
        } catch {
            logger.error("Failed to get cache info: \(error.localizedDescription)")
        }
    }
}
