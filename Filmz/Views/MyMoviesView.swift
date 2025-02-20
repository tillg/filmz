import SwiftUI

struct MyMoviesView: View {
    @ObservedObject var filmStore: FilmStore

    var body: some View {
        NavigationView {
            List {
                ForEach(filmStore.films) { film in
                    FilmRow(film: film, filmStore: filmStore)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        Task {
                            // Remove from CloudKit and local store
                            await filmStore.deleteFilm(filmStore.films[index])
                        }
                    }
                }
            }
            .navigationTitle("My Movies")
        }
    }
}
