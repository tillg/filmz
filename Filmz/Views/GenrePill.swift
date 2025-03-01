import SwiftUI

struct GenrePill: View {
    let genre: String
    
    var body: some View {
        Text(genre)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.secondary.opacity(0.2))
            .clipShape(Capsule())
    }
} 

#Preview {
    HStack {
        GenrePill(genre: "Action")
        GenrePill(genre: "Thriller")
        GenrePill(genre: "Crime")
        GenrePill(genre: "Comedy")
        GenrePill(genre: "Drama")
        GenrePill(genre: "Horror")
        GenrePill(genre: "Sci-Fi")
    }
}
