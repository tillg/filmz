func debugCacheInfo() {
    do {
        let files = try fileManager.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
        let totalSize = files.reduce(0) { [self] sum, url in
            guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize else { return sum }
            return sum + size
        }
        
        logger.debug("""
            📁 Cache Directory: \(self.cacheDirectory.path)
            📊 Files in cache: \(files.count)
            💾 Total size: \(Double(totalSize) / 1_000_000.0) MB
            🧠 Memory cache count: \(self.cache.totalCostLimit)
            """)
    } catch {
        logger.error("Failed to get cache info: \(error.localizedDescription)")
    }
} 