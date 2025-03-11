import SwiftUI

struct FilmFormView: View {
    let filmStore: FilmStore
    @Environment(\.dismiss) private var dismiss
    
    // Optional film for edit mode, nil for add mode
    let existingFilm: Film?
    // Required for add mode
    let imdbResult: IMDBService.SearchResult?
    
    @State private var selectedGenres: Set<String>
    @State private var watchStatus: Bool
    @State private var watchDate: Date?
    @State private var streamingService = ""
    @State private var recommendedBy: String
    @State private var audience: Film.AudienceType
    
    init(filmStore: FilmStore, existingFilm: Film? = nil, imdbResult: IMDBService.SearchResult? = nil) {
        self.filmStore = filmStore
        self.existingFilm = existingFilm
        self.imdbResult = imdbResult
        
        // Initialize state from existing film or defaults
        if let film = existingFilm {
            _selectedGenres = State(initialValue: Set(film.genres))
            _watchStatus = State(initialValue: film.watched)
            _watchDate = State(initialValue: film.watchDate)
            _streamingService = State(initialValue: film.streamingService ?? "")
            _recommendedBy = State(initialValue: film.recommendedBy ?? "")
            _audience = State(initialValue: film.intendedAudience)
        } else {
            _selectedGenres = State(initialValue: Set())
            _watchStatus = State(initialValue: false)
            _watchDate = State(initialValue: nil)
            _streamingService = State(initialValue: "")
            _recommendedBy = State(initialValue: "")
            _audience = State(initialValue: .alone)
        }
    }
    
    let availableGenres = ["Action", "Adventure", "Comedy", "Drama", "Horror", "Sci-Fi", "Thriller"]
    
    var body: some View {
        Form {
            Section(header: Text("Movie Details")) {
                if let film = existingFilm {
                    PosterImage(imageUrl: film.posterUrl)
                        .frame(maxHeight: 200)
                } else if let result = imdbResult {
                    PosterImage(imageUrl: result.Poster)
                        .frame(maxHeight: 200)
                }
                
                Text(existingFilm?.title ?? imdbResult?.Title ?? "")
                    .font(.headline)
                Text("Year: \(existingFilm?.year ?? imdbResult?.Year ?? "")")
                
                if let film = existingFilm {
                    if film.imdbRating > 0 {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text("IMDB Rating: \(String(format: "%.1f", film.imdbRating))/10")
                        }
                    }
                    
                    if !film.plot.isEmpty {
                        Text(film.plot)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
            }
            
            Section("Genres") {
                if existingFilm != nil {
                    // Show pills for existing film
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(Array(selectedGenres), id: \.self) { genre in
                                GenrePill(genre: genre)
                            }
                        }
                        .padding(.horizontal)
                    }
                } else {
                    // Show toggles for new film
                    ForEach(availableGenres, id: \.self) { genre in
                        Toggle(genre, isOn: Binding(
                            get: { selectedGenres.contains(genre) },
                            set: { isSelected in
                                if isSelected {
                                    selectedGenres.insert(genre)
                                } else {
                                    selectedGenres.remove(genre)
                                }
                            }
                        ))
                    }
                }
            }
            
            Section("Watch Status") {
                Toggle("Watched", isOn: $watchStatus)
                
                if watchStatus {
                    DatePicker("Watch Date", selection: .init(
                        get: { watchDate ?? Date() },
                        set: { watchDate = $0 }
                    ), displayedComponents: .date)
                    
                    TextField("Streaming Service", text: $streamingService)
                }
            }
            
            Section("Additional Info") {
                TextField("Recommended By", text: $recommendedBy)
                
                Picker("Intended Audience", selection: $audience) {
                    Text("Me alone").tag(Film.AudienceType.alone)
                    Text("Me and partner").tag(Film.AudienceType.partner)
                    Text("Family").tag(Film.AudienceType.family)
                }
            }
            
            Section {
                Button(existingFilm != nil ? "Save Changes" : "Add Film") {
                    Task {
                        if let film = existingFilm {
                            await filmStore.updateFilm(film, with: EditedFilmData(
                                genres: Array(selectedGenres),
                                recommendedBy: recommendedBy,
                                intendedAudience: audience,
                                watched: watchStatus,
                                watchDate: watchStatus ? watchDate : nil,
                                streamingService: watchStatus ? streamingService : nil
                            ))
                        } else if let result = imdbResult {
                            let film = Film(
                                imdbId: result.imdbID,
                                title: result.Title,
                                year: result.Year,
                                genres: Array(selectedGenres),
                                imdbRating: 0.0,
                                posterUrl: result.Poster,
                                description: "",
                                country: "",
                                language: "",
                                releaseDate: Date(),
                                runtime: 0,
                                plot: "",
                                recommendedBy: recommendedBy,
                                intendedAudience: audience,
                                watched: watchStatus,
                                watchDate: watchStatus ? watchDate : nil,
                                streamingService: watchStatus ? streamingService : nil
                            )
                            await filmStore.addFilm(film)
                        }
                        dismiss()
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(existingFilm != nil ? "Edit Film" : "Add Film")
    }
} 
