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
            _watchStatus = State(initialValue: false) // TODO: Add to model
            _recommendedBy = State(initialValue: film.recommendedBy ?? "")
            _audience = State(initialValue: film.intendedAudience)
        } else {
            _selectedGenres = State(initialValue: Set())
            _watchStatus = State(initialValue: false)
            _recommendedBy = State(initialValue: "")
            _audience = State(initialValue: .alone)
        }
    }
    
    let availableGenres = ["Action", "Adventure", "Comedy", "Drama", "Horror", "Sci-Fi", "Thriller"]
    
    var body: some View {
        Form {
            Section("Movie Details") {
                let imageUrl = existingFilm?.posterUrl ?? imdbResult?.Poster
                AsyncImage(url: URL(string: imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(systemName: "film")
                        .foregroundStyle(.gray)
                }
                .frame(maxHeight: 200)
                
                Text(existingFilm?.title ?? imdbResult?.Title ?? "")
                    .font(.headline)
                Text("Year: \(existingFilm?.year ?? imdbResult?.Year ?? "")")
            }
            
            Section("Genres") {
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
                                intendedAudience: audience
                            ))
                        } else if let result = imdbResult {
                            let film = Film(
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
                                intendedAudience: audience
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