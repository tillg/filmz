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

struct GenrePillsHList: View {
    let genres: [String]
    var body: some View {
        if genres.isEmpty {
            EmptyView()
        } else {
            HStack {
                ForEach(genres, id: \.self) { genre in
                    GenrePill(genre: genre)
                }
            }
        }
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
