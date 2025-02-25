import SwiftUI

struct ContentView: View {
    @StateObject private var filmStore = FilmStore()

    var body: some View {
        TabView {
            MyMoviesView(filmStore: filmStore)
                .tabItem {
                    Label("My Movies", systemImage: "film")
                }

            SearchFilmsView(filmStore: filmStore)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            // #if DEBUG  2025-02-14 TODO Could not figure out how to set/unset DEBUG
            CacheView()
                .tabItem {
                    Label("Cache", systemImage: "gear")
                }
            // #endif
        }
    }
}

#Preview {
    ContentView()
} 
