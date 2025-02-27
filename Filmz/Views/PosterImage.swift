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
    
    // We can call a posterImage w/o any image - it will show a placeholder
    init() {
        self.imageUrl = URL(string: "")!
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
