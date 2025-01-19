import SwiftUI

struct FilmRow: View {
    let film: Film
    let filmStore: FilmStore
    
    var body: some View {
        NavigationLink(destination: EditFilmView(film: film, filmStore: filmStore)) {
            HStack {
                AsyncImage(url: URL(string: film.posterUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "film")
                        .foregroundStyle(.gray)
                }
                .frame(width: 50, height: 75)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(film.title)
                        .font(.headline)
                    Text(film.year)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if let rating = film.myRating {
                    Text("\(rating)/10")
                        .font(.caption)
                        .padding(6)
                        .background(.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .padding(.vertical, 4)
        }
    }
} 