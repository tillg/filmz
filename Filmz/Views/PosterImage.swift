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
/// PosterImage(film: film)
///     .frame(width: 50, height: 75)
///     .cornerRadius(8)
/// ```
struct PosterImage: View {
    /// The film whose poster to display
    let film: Film
    
    /// Shared image cache instance
    @StateObject private var imageCache = PosterImageCache.shared
    
    /// Currently loaded image
    @State private var image: Image?
    
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
            image = await imageCache.image(for: film)
        }
    }
}
