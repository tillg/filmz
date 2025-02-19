import SwiftUI

struct FilmRow: View {
    let film: Film
    let filmStore: FilmStore
    
    var body: some View {
        NavigationLink(destination: FilmFormView(filmStore: filmStore, existingFilm: film)) {
            HStack {
                PosterImage(imageUrl: film.posterUrl)
                    .frame(width: 50, height: 75)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(film.title)
                        .font(.headline)
                    HStack(spacing: 4) {
                        Text(film.year)
                        Text("•")
                        if film.imdbRating > 0 {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .imageScale(.small)
                            Text(String(format: "%.1f", film.imdbRating))
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    FlowLayout(spacing: 4) {
                        ForEach(film.genres, id: \.self) { genre in
                            GenrePill(genre: genre)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    if film.watched {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            if let watchDate = film.watchDate {
                                Text("Watched on \(watchDate.formatted(date: .abbreviated, time: .omitted))")
                            } else {
                                Text("Watched")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    
                    if abs(film.dateAdded.timeIntervalSinceNow) > 5 {
                        Text("Added \(film.dateAdded.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
