import SwiftUI
import Kingfisher

struct ContentView: View {
    @StateObject private var filmStore = FilmStore()
    @State private var watchFilter: FilmListView.WatchFilter = .all

    var body: some View {
        NavigationStack {
            TabView {
                FilmListView(filmStore: filmStore, watchFilter: $watchFilter)
                    .tabItem {
                        Label("My Filmz", systemImage: "film")
                    }

                SearchFilmsView(filmStore: filmStore)
                    .tabItem {
                        Label("Add Film", systemImage: "plus")
                    }
            }
        }
    }
}
