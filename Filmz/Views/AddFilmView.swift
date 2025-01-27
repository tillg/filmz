import SwiftUI

struct AddFilmView: View {
    let imdbResult: IMDBService.SearchResult
    let filmStore: FilmStore
    let dismiss: DismissAction
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
    @State private var detailsError: Error?
    @State private var movieDetails: IMDBService.DetailResponse?

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
                
                if let details = movieDetails {
                    if details.imdbRating != "N/A", let rating = Double(details.imdbRating), rating > 0 {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text("IMDB Rating: \(details.imdbRating)/10")
                        }
                        .padding(.top, 4)
                    }
                    
                    if details.Plot != "N/A" {
                        Text(details.Plot)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
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
                            imdbRating: movieDetails?.imdbRatingDouble ?? 0.0,
                            posterUrl: imdbResult.Poster,
                            description: movieDetails?.Plot ?? "",
                            country: movieDetails?.Country ?? "",
                            language: movieDetails?.Language ?? "",
                            releaseDate: Date(),
                            runtime: movieDetails?.runtimeMinutes ?? 0,
                            plot: movieDetails?.Plot ?? "",
                            recommendedBy: recommendedBy,
                            intendedAudience: audience,
                            watched: watchStatus,
                            watchDate: watchStatus ? watchDate : nil,
                            streamingService: watchStatus ? streamingService : nil
                        )
                        
                        // Save the film first
                        await filmStore.addFilm(film)
                        
                        // Then try to fetch and update additional details
                        if let details = await loadMovieDetails() {
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
            // Initial fetch of genres and details
            if let details = await loadMovieDetails() {
                movieDetails = details
                genres = details.Genre.components(separatedBy: ", ")
            }
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
        .alert("Error Loading Movie Details", isPresented: .init(get: { detailsError != nil }, set: { _ in detailsError = nil })) {
            Button("OK") {}
        } message: {
            Text(detailsError?.localizedDescription ?? "Unknown error")
        }
    }
    
    private func loadMovieDetails() async -> IMDBService.DetailResponse? {
        do {
            let imdbService = try IMDBService()
            let details = try await imdbService.fetchMovieDetails(imdbId: imdbResult.imdbID)
            movieDetails = details
            return details
        } catch {
            detailsError = error
            return nil
        }
    }
}