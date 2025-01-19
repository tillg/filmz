import SwiftUI

struct FilmListView: View {
    let films: [Film]
    let filmStore: FilmStore
    @Binding var watchFilter: WatchFilter
    
    enum WatchFilter {
        case all, watched, unwatched
        
        var title: String {
            switch self {
            case .all: return "All"
            case .watched: return "Watched"
            case .unwatched: return "Unwatched"
            }
        }
    }
    
    var filteredFilms: [Film] {
        switch watchFilter {
        case .all:
            return films
        case .watched:
            return films.filter { $0.watched }
        case .unwatched:
            return films.filter { !$0.watched }
        }
    }
    
    var body: some View {
        VStack {
            Picker("Filter", selection: $watchFilter) {
                ForEach([WatchFilter.all, .watched, .unwatched], id: \.title) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            List {
                ForEach(filteredFilms) { film in
                    FilmRow(film: film, filmStore: filmStore)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        Task {
                            await filmStore.deleteFilm(filteredFilms[index])
                        }
                    }
                }
            }
        }
    }
} 