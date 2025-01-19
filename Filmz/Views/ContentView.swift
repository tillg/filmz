import SwiftUI

struct ContentView: View {
    @StateObject private var filmStore = FilmStore()
    @State private var showingSearch = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filmStore.films) { film in
                    FilmRow(film: film, filmStore: filmStore)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        Task {
                            await filmStore.deleteFilm(filmStore.films[index])
                        }
                    }
                }
            }
            .navigationTitle("My Filmz")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSearch = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingSearch) {
                SearchFilmsView(filmStore: filmStore)
            }
        }
    }
}

#Preview {
    ContentView()
} 
