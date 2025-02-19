import SwiftUI

struct ContentView: View {
    @StateObject private var filmStore = FilmStore()
    @State private var showingSearch = false
    @State private var watchFilter: FilmListView.WatchFilter = .all
    
    var body: some View {
        TabView {
            SearchFilmsView(filmStore: filmStore)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            
            MyMoviesView()
                .tabItem {
                    Label("My Movies", systemImage: "film")
                }
            
            CacheTestView()
                .tabItem {
                    Label("Cache Test", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
} 
