import Foundation
import SwiftUI
import CloudKit
import OSLog
import CryptoKit

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
    
    /// Retrieves an image for the given URL string.
    /// If the image is not already cached locally, it is downloaded from the original URL,
    /// stored in the local cache, and then uploaded to the CloudKit shared area.
    ///
    /// - Parameter urlString: The URL string for the image.
    /// - Returns: A SwiftUI Image if successful, or nil otherwise.
    func image(for urlString: String) async -> Image? {
        let key = urlString as NSString
        
        // 1. Check the in-memory cache.
        if let cachedImage = cache.object(forKey: key) {
            return Image(uiImage: cachedImage)
        }
        
        // 2. Check the disk cache.
        let fileName = urlString.sha256()
        let fileUrl = cacheDirectory.appendingPathComponent(fileName)
        if let imageData = try? Data(contentsOf: fileUrl),
           let diskImage = UIImage(data: imageData) {
            cache.setObject(diskImage, forKey: key)
            return Image(uiImage: diskImage)
        }
        
        // 3. Download the image from its original URL.
        guard let url = URL(string: urlString) else {
            logger.error("Invalid URL: \(urlString)")
            return nil
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let downloadedImage = UIImage(data: data) {
                // Cache in memory and on disk.
                cache.setObject(downloadedImage, forKey: key)
                try? data.write(to: fileUrl)
                
                // 4. Upload to CloudKit shared area asynchronously.
                Task {
                    await self.uploadImageToCloudKit(urlString: urlString, imageData: data)
                }
                
                return Image(uiImage: downloadedImage)
            }
        } catch {
            logger.error("Failed to download image: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Uploads image data to the CloudKit shared area by creating a CKRecord.
    ///
    /// - Parameters:
    ///   - urlString: The URL string associated with the image.
    ///   - imageData: The downloaded image data.
    private func uploadImageToCloudKit(urlString: String, imageData: Data) async {
        // Write imageData to a temporary file.
        let temporaryFileURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try imageData.write(to: temporaryFileURL)
            let asset = CKAsset(fileURL: temporaryFileURL)
            
            // Create a new record with type "CachedImage" and assign the URL and asset.
            let record = CKRecord(recordType: "CachedImage")
            record["url"] = urlString as CKRecordValue
            record["asset"] = asset
            
            // Save the record to the public (shared) CloudKit database.
            let container = CKContainer.default()
            let database = container.publicCloudDatabase
            _ = try await database.save(record)
            logger.debug("Uploaded image to CloudKit for URL: \(urlString)")
        } catch {
            logger.error("Error uploading image to CloudKit: \(error.localizedDescription)")
        }
        // Clean up the temporary file.
        try? fileManager.removeItem(at: temporaryFileURL)
    }
    
    /// Clears all cached images from both memory and disk.
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}
