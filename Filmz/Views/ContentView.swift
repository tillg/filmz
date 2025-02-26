import SwiftUI
import Kingfisher

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
        }
    }
}

#Preview {
    ContentView()
} 
