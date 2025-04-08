import SwiftUI

struct FilmRow: View {
    //@Binding var myFilm: MyFilm
    let myFilmId: UUID
    private let myFilmStore: MyFilmStore
    private var myFilm: MyFilm
    @State private var imdbFilm: ImdbFilm? = nil
    
    init(myFilmId: UUID, filmStore: MyFilmStore) {
            self.myFilmId = myFilmId
            self.myFilmStore = filmStore
            self.myFilm = filmStore.getFilmById(myFilmId)!
        }
    
    var body: some View {
        NavigationLink(destination: MyFilmDetailView(viewModel: MyFilmDetailViewModel(myFilmId: myFilmId,  filmStore: myFilmStore)))
        {
            HStack {
                PosterImage(imageUrl: imdbFilm?.posterUrl)
                    .frame(width: 50, height: 75)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(imdbFilm?.title ??  "Untitled")
                        .font(.headline)
                    HStack(spacing: 4) {
                        Text(imdbFilm?.year ?? "Unknown")
                        if imdbFilm?.imdbRating ?? 0 > 0 {
                            Text("•")
                        }
                        ImdbRatingView(rating: imdbFilm?.imdbRating ?? 0)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    GenrePillsHList(genres: imdbFilm?.genres ?? [])
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    if myFilm.watched {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            if let watchDate = myFilm.watchDate {
                                Text("Watched on \(watchDate.formatted(date: .abbreviated, time: .omitted))")
                            } else {
                                Text("Watched")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    
                    if abs(myFilm.dateAdded.timeIntervalSinceNow) > 5 {
                        Text("Added \(myFilm.dateAdded.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if let rating = myFilm.myRating {
                    Text("\(rating)/10")
                        .font(.caption)
                        .padding(6)
                        .background(.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .padding(.vertical, 4)
        }
        .task {
            do {
                imdbFilm = try await myFilm.imdbFilm
            } catch {
                logger.error("Error loading film details: \(error)")
            }
        }
    }
}


#Preview {
    let myFilmRepository = MyFilmRepositoryMock()
    let filmStore = MyFilmStore(myFilmRepository: myFilmRepository)
    List {
        FilmRow(myFilmId: myFilmRepository.films[0].id, filmStore: filmStore)
            .border(Color.red)
        FilmRow(myFilmId: myFilmRepository.films[1].id, filmStore: filmStore)
            .border(Color.red)
    }
}
