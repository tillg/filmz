import SwiftUI
import Kingfisher

struct PosterImage: View {
    let imageUrl: URL?
    let placeholderImage = Image("placeholder")

    init(imageUrl: URL?) {
        self.imageUrl = imageUrl
    }

    init(imageUrl: String?) {
        self.imageUrl = URL(string: imageUrl ?? "")
    }

    // Default init: sets `imageUrl` to nil
    init() {
        self.imageUrl = nil
    }

    var body: some View {
        KFImage.url(self.imageUrl)
            .placeholder {
                placeholderImage
                    .resizable()
                    .scaledToFit()
            }
    }
}
