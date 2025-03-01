import SwiftUI
import CoreData

struct FilmListView: View {
    @ObservedObject var filmStore: FilmStore  // Changed from @StateObject to @ObservedObject
    @Binding var watchFilter: WatchFilter
    @State private var selectedGenre: String?
    
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
    
    var availableGenres: [String] {
        // Get unique genres from all films
        let genres = Set(filmStore.films.flatMap { $0.genres }).sorted()
        return genres
    }
    
    var filteredAndSortedFilms: [Film] {
        var filtered = filmStore.films
        
        // Apply watch filter
        switch watchFilter {
        case .all: break
        case .watched:
            filtered = filtered.filter { $0.watched }
        case .unwatched:
            filtered = filtered.filter { !$0.watched }
        }
        
        // Apply genre filter if selected
        if let genre = selectedGenre {
            filtered = filtered.filter { $0.genres.contains(genre) }
        }
        
        // Apply sorting
        return SortOption.sort(filtered, by: filmStore.sortOption)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filters and Sort
            HStack {
                // Watch Status Filter
                Picker("Filter", selection: $watchFilter) {
                    ForEach([WatchFilter.all, .watched, .unwatched], id: \.title) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                
                // Sort Menu
                Menu {
                    ForEach([SortOption.dateAdded, .title, .year], id: \.title) { option in
                        Button(action: { filmStore.sortOption = option }) {
                            HStack {
                                Text(option.title)
                                if filmStore.sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .imageScale(.large)
                }
            }
            .padding()
            
            // Genre Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    GenreButton(genre: "All Genres", action:  { selectedGenre = nil }, isActive: (selectedGenre == nil))
                    
                    ForEach(availableGenres, id: \.self) { genre in
                        GenreButton(genre: genre, action: { selectedGenre = genre }, isActive: selectedGenre == genre)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
            
            if filmStore.isLoading {
                Spacer()
                ProgressView()
                    .padding()
                Spacer()
            } else if filteredAndSortedFilms.isEmpty {
                Spacer()
                Text("No films found")
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            } else {
                List {
                    ForEach(filteredAndSortedFilms) { film in
                        FilmRow(film: film, filmStore: filmStore)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            Task {
                                await filmStore.deleteFilm(filteredAndSortedFilms[index])
                            }
                        }
                    }
                }
                .padding(.bottom, 10)
            }
        }
    }
}
