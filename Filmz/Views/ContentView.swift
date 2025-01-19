import SwiftUI

struct ContentView: View {
    @StateObject private var filmStore = FilmStore()
    @State private var showingSearch = false
    @State private var watchFilter: FilmListView.WatchFilter = .all
    
    var body: some View {
        NavigationView {
            FilmListView(
                films: filmStore.films,
                filmStore: filmStore,
                watchFilter: $watchFilter
            )
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
