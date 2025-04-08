import Kingfisher
import SwiftUI

struct ContentView: View {
    @State private var isInitialized = false
    @State private var myFilmStore: MyFilmStore = MyFilmStore()
    @State private var watchFilter: FilmListView.WatchFilter = .all
    
    var body: some View {
        Group {
            NavigationStack {
                TabView {
                    FilmListView(myFilmStore: myFilmStore)
                    .tabItem {
                        Label("My Filmz", systemImage: "film")
                    }
                    
                    SearchFilmsView(filmStore: myFilmStore)
                        .tabItem {
                            Label("Add Film", systemImage: "plus")
                        }
                }
            }
        }
    }
    
}

#Preview {
    ContentView()
}
