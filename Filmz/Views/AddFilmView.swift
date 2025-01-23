import SwiftUI

struct AddFilmView: View {
    let imdbResult: IMDBService.SearchResult
    let filmStore: FilmStore
    let dismiss: DismissAction
    private let imdbService = IMDBService()
    
    @State private var isLoading = false
    @State private var genres: [String] = []
    @State private var watchStatus = false
    @State private var watchDate: Date?
    @State private var streamingService = ""
    @State private var recommendedBy = ""
    @State private var audience = Film.AudienceType.alone
    @State private var film: Film?
    @State private var showingError = false
    @State private var error: Error?
    @State private var showingDuplicateAlert = false
    
    var body: some View {
        Form {
            Section("Movie Details") {
                AsyncImage(url: URL(string: imdbResult.Poster)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(systemName: "film")
                        .foregroundStyle(.gray)
                }
                .frame(maxHeight: 200)
                
                Text(imdbResult.Title)
                    .font(.headline)
                Text("Year: \(imdbResult.Year)")
            }
            
            if !genres.isEmpty {
                Section("Genres") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(genres, id: \.self) { genre in
                                GenrePill(genre: genre)
                            }
                        }
                        .padding(.horizontal)
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
                Button(action: {
                    isLoading = true
                    Task {
                        // Check if film exists
                        if filmStore.films.contains(where: { 
                            $0.title.lowercased() == imdbResult.Title.lowercased() && 
                            $0.year == imdbResult.Year 
                        }) {
                            isLoading = false
                            showingDuplicateAlert = true
                            return
                        }
                        
                        // Create film with basic info first
                        let film = Film(
                            title: imdbResult.Title,
                            year: imdbResult.Year,
                            genres: genres,
                            imdbRating: 0.0,
                            posterUrl: imdbResult.Poster,
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
                        
                        // Save the film first
                        await filmStore.addFilm(film)
                        
                        // Then try to fetch and update additional details
                        if let details = try? await imdbService.fetchMovieDetails(imdbId: imdbResult.imdbID) {
                            // Update with full details
                            let updatedFilm = Film(
                                title: details.Title,
                                year: details.Year,
                                genres: details.Genre.components(separatedBy: ", "),
                                imdbRating: Double(details.imdbRating) ?? 0.0,
                                posterUrl: details.Poster,
                                description: details.Plot,
                                country: details.Country,
                                language: details.Language,
                                releaseDate: Date(),
                                runtime: Int(details.Runtime.replacingOccurrences(of: " min", with: "")) ?? 0,
                                plot: details.Plot,
                                recommendedBy: recommendedBy,
                                intendedAudience: audience,
                                watched: watchStatus,
                                watchDate: watchStatus ? watchDate : nil,
                                streamingService: watchStatus ? streamingService : nil
                            )
                            
                            await filmStore.updateFilm(updatedFilm, with: EditedFilmData(
                                genres: updatedFilm.genres,
                                recommendedBy: updatedFilm.recommendedBy ?? "",
                                intendedAudience: updatedFilm.intendedAudience,
                                watched: watchStatus,
                                watchDate: watchStatus ? watchDate : nil,
                                streamingService: watchStatus ? streamingService : nil
                            ))
                        }
                        
                        dismiss()
                        isLoading = false
                    }
                }) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Save")
                    }
                }
                .frame(maxWidth: .infinity)
                .disabled(isLoading)
            }
        }
        .navigationTitle("Add Film")
        .task {
            // Initial fetch of genres
            if let details = try? await imdbService.fetchMovieDetails(imdbId: imdbResult.imdbID) {
                genres = details.Genre.components(separatedBy: ", ")
            }
        }
        .task {
            // Remove the do-catch since Film initialization doesn't throw
            let details = try? await IMDBService().fetchMovieDetails(imdbId: imdbResult.imdbID)
            
            if let details = details {
                // Convert IMDb rating to Double
                let rating = Double(details.imdbRating) ?? 0.0
                
                // Parse genres
                let genres = details.Genre.components(separatedBy: ", ")
                
                // Parse runtime to minutes
                let runtime = details.Runtime.components(separatedBy: " ").first.flatMap(Int.init) ?? 0
                
                film = Film(
                    title: details.Title,
                    year: details.Year,
                    genres: genres,
                    imdbRating: rating,
                    posterUrl: details.Poster,
                    description: details.Plot,
                    country: details.Country,
                    language: details.Language,
                    releaseDate: Date(),
                    runtime: runtime,
                    plot: details.Plot,
                    recommendedBy: recommendedBy,
                    intendedAudience: audience,
                    watched: watchStatus,
                    watchDate: watchStatus ? watchDate : nil,
                    streamingService: watchStatus ? streamingService : nil
                )
            } else {
                error = NSError(domain: "AddFilmView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load film details"])
                showingError = true
            }
            
            isLoading = false
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(error?.localizedDescription ?? "Unknown error")
        }
        .alert("Movie Already in Library", isPresented: $showingDuplicateAlert) {
            Button("OK") {}
        } message: {
            Text("\(imdbResult.Title) (\(imdbResult.Year)) is already in your library.")
        }
    }
} 