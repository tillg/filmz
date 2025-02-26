import SwiftUI
import Kingfisher

struct PosterImage: View {
    let imageUrl: URL
    //let placeholderImageUrl = Bundle.main.url(forResource: "icon-1024", withExtension: "png")!
    let placeholderImage = Image("icon-1024")

    init(imageUrl: URL) {
        self.imageUrl = imageUrl
    }
    
    init(imageUrl: String) {
        self.imageUrl = URL(string: imageUrl)!
    }
    
    var body: some View {
        KFImage.url(self.imageUrl)
            .placeholder {
                // Use your placeholderImage (a SwiftUI Image) as the placeholder view
                placeholderImage
                    .resizable()
                    .scaledToFit()
            }
    }
}
