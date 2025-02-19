import SwiftUI

/// A reusable SwiftUI view that displays a film's poster image
/// with efficient caching and loading.
///
/// This view:
/// - Uses PosterImageCache for efficient image loading and caching
/// - Shows a placeholder while loading
/// - Handles loading errors gracefully
/// - Automatically resizes images while maintaining aspect ratio
///
/// Example usage:
/// ```swift
/// PosterImage(imageUrl: film.posterUrl)
///     .frame(width: 50, height: 75)
///     .cornerRadius(8)
/// ```
struct PosterImage: View {
    /// The URL of the poster image to display
    let imageUrl: URL
    
    /// Shared image cache instance
    @StateObject private var imageCache = ImageCache.shared
    
    /// Currently loaded image
    @State private var image: Image?
    
    // Primary initializer with a URL
    init(imageUrl: URL) {
        self.imageUrl = imageUrl
    }
    
    // Convenience initializer that accepts a String.
    init(imageUrl: String) {
        // Convert the string to a URL. You can provide a fallback if needed.
        if let url = URL(string: imageUrl) {
            self.imageUrl = url
        } else {
            // Fallback: you can choose to either fatalError, or use a placeholder URL.
            self.imageUrl = URL(string: "https://example.com/placeholder.png")!
        }
    }
    
    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "film")
                    .foregroundStyle(.gray)
            }
        }
        .task {
            // Now imageUrl is always a URL.
            image = await imageCache.image(for: imageUrl.absoluteString)
        }
    }
}
