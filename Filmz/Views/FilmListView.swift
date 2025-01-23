import SwiftUI

struct FilmListView: View {
    let films: [Film]
    let filmStore: FilmStore
    @Binding var watchFilter: WatchFilter
    @State private var selectedGenre: String?
    @State private var sortOption: SortOption = .dateAdded
    
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
    
    enum SortOption {
        case title, year, dateAdded
        
        var title: String {
            switch self {
            case .title: return "Title"
            case .year: return "Year"
            case .dateAdded: return "Date Added"
            }
        }
    }
    
    var availableGenres: [String] {
        // Get unique genres from all films
        let genres = Set(films.flatMap { $0.genres }).sorted()
        return genres
    }
    
    var filteredAndSortedFilms: [Film] {
        var filtered = films
        
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
        return filtered.sorted { first, second in
            switch sortOption {
            case .title:
                return first.title.lowercased() < second.title.lowercased()
            case .year:
                return first.year > second.year // Newest first
            case .dateAdded:
                // If both have valid dates (more than 5 seconds old)
                if abs(first.dateAdded.timeIntervalSinceNow) > 5 && abs(second.dateAdded.timeIntervalSinceNow) > 5 {
                    return first.dateAdded > second.dateAdded // Most recent first
                }
                // If only first has valid date, it goes first
                if abs(first.dateAdded.timeIntervalSinceNow) > 5 {
                    return true
                }
                // If only second has valid date, it goes first
                if abs(second.dateAdded.timeIntervalSinceNow) > 5 {
                    return false
                }
                // If neither has valid date, sort by title
                return first.title.lowercased() < second.title.lowercased()
            }
        }
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
                        Button(action: { sortOption = option }) {
                            HStack {
                                Text(option.title)
                                if sortOption == option {
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
                    Button(action: { selectedGenre = nil }) {
                        Text("All Genres")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedGenre == nil ? Color.accentColor : Color.gray.opacity(0.2))
                            .foregroundColor(selectedGenre == nil ? .white : .primary)
                            .cornerRadius(16)
                    }
                    
                    ForEach(availableGenres, id: \.self) { genre in
                        Button(action: { selectedGenre = genre }) {
                            Text(genre)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedGenre == genre ? Color.accentColor : Color.gray.opacity(0.2))
                                .foregroundColor(selectedGenre == genre ? .white : .primary)
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
            
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
        }
    }
} 