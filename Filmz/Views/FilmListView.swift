import SwiftUI
import Combine
import CoreData
import Logging

struct FilmListView: View {
    let myFilmStore: MyFilmStore
    @State private var filteredAndSortedMyFilms: [MyFilm] = []
    @State private var watchFilter: WatchFilter = .all
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
    
    func filterAndSortMyFilms() async -> [MyFilm] {
        let logger = Logger(label: "FilmListView")
        logger.info("filterAndSortMyFilms: Filtering and sorting films...")
        var filtered = myFilmStore.myFilms
        
        // Apply watch filter (synchronous)
        switch watchFilter {
        case .all:
            break
        case .watched:
            filtered = filtered.filter { $0.watched }
        case .unwatched:
            filtered = filtered.filter { !$0.watched }
        }
        
        // Apply genre filter asynchronously if a genre is selected
        if let genre = selectedGenre {
            var asyncFiltered: [MyFilm] = []
            for film in filtered {
                do {
                    // Await the asynchronous property access
                    if let details = try await film.imdbFilm,
                       details.genres.contains(genre) {
                        asyncFiltered.append(film)
                    }
                } catch {
                    logger.error("Error fetching details for film \(film.id): \(error)")
                }
            }
            filtered = asyncFiltered
        }
        
        // Apply sorting (synchronous)
        return SortOption.sort(filtered, by: myFilmStore.sortOption)
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
                        Button(action: { myFilmStore.sortOption = option }) {
                            HStack {
                                Text(option.title)
                                if myFilmStore.sortOption == option {
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
                    
                    ForEach(myFilmStore.genres, id: \.self) { genre in
                        GenreButton(genre: genre, action: { selectedGenre = genre }, isActive: selectedGenre == genre)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
            
            if myFilmStore.isLoading {
                Spacer()
                ProgressView()
                    .padding()
                Spacer()
            } else if filteredAndSortedMyFilms.isEmpty {
                Spacer()
                Text("No films found")
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            } else {
                filmList
            }
        }
        .task(id: myFilmStore.isLoading) {
            if !myFilmStore.isLoading {
                filteredAndSortedMyFilms = await filterAndSortMyFilms()
            }
        }
        .onChange(of: watchFilter) { _, _ in
            Task {
                filteredAndSortedMyFilms = await filterAndSortMyFilms()
            }
        }
        .onChange(of: selectedGenre) { _, _ in
            Task {
                filteredAndSortedMyFilms = await filterAndSortMyFilms()
            }
        }
        .onChange(of: myFilmStore.sortOption) { _, _ in
            Task {
                filteredAndSortedMyFilms = await filterAndSortMyFilms()
            }
        }
    }
    
    private var filmRows: some View {
        ForEach(filteredAndSortedMyFilms, id: \.id) { film in
            FilmRow(myFilmId: film.id, filmStore: myFilmStore)
        }
        .onDelete(perform: deleteFilms)
    }

    private var filmList: some View {
        List {
            filmRows
        }
        .padding(.bottom, 10)
        .onAppear {
            let listLogger = Logger(label: "FilmListView - filmList")
            listLogger.info("filmList onAppear")
        }
    }

    private func deleteFilms(at offsets: IndexSet) {
        for index in offsets {
            Task {
                await myFilmStore.deleteMyFilm(filteredAndSortedMyFilms[index])
            }
        }
    }
}


#Preview {
    let mockStore = MyFilmStore(myFilmRepository: MyFilmRepositoryMock())
    FilmListView(myFilmStore: mockStore)
}
