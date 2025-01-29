import SwiftUI

struct PosterImage: View {
    let film: Film
    @StateObject private var imageCache = PosterImageCache.shared
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
