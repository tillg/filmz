import SwiftUI
import OSLog

struct MovieDetailView: View {
    let result: IMDBService.SearchResult
    @State private var watchStatus = false
    @State private var watchDate: Date = Date()
    @State private var streamingService = ""
    @State private var recommendedBy = ""
    @State private var movieDetails: IMDBService.DetailResponse?
    @State private var isLoading = true
    @State private var error: Error?
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "MovieDetailView")
    
    var body: some View {
        List {
            if isLoading {
                Section {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            } else if let error = error {
                Section {
                    Text("Failed to load details: \(error.localizedDescription)")
                        .foregroundStyle(.red)
                }
            } else {
                // Movie Poster and Basic Info
                Section {
                    PosterImage(imageUrl: result.Poster)
                            .frame(maxHeight: 300)
                    
                    Text(result.Title)
                        .font(.headline)
                    Text("Year: \(result.Year)")
                        .foregroundStyle(.secondary)
                    
                    if let details = movieDetails {
                        if details.imdbRating != "N/A" {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                Text("IMDB Rating: \(details.imdbRating)/10")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if details.Runtime != "N/A" {
                            Text("Runtime: \(details.Runtime)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Plot
                if let details = movieDetails, details.Plot != "N/A" {
                    Section("Plot") {
                        Text(details.Plot)
                            .font(.body)
                    }
                }
                
                // Watch Status
                Section("Watch Status") {
                    Toggle("Watched", isOn: $watchStatus)
                    
                    if watchStatus {
                        DatePicker("Watch Date", selection: $watchDate, displayedComponents: .date)
                        TextField("Streaming Service", text: $streamingService)
                    }
                }
                
                // Additional Info
                Section("Additional Information") {
                    TextField("Recommended By", text: $recommendedBy)
                }
                
                // Save Button
                Section {
                    Button(action: {
                        // TODO: Implement save functionality
                    }) {
                        Text("Save to My Movies")
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .navigationTitle("Movie Details")
        .task {
            await loadMovieDetails()
        }
    }
    
    private func loadMovieDetails() async {
        isLoading = true
        do {
            let imdbService = try IMDBService()
            movieDetails = try await imdbService.fetchMovieDetails(imdbId: result.imdbID)
        } catch {
            logger.error("Failed to load movie details: \(error)")
            self.error = error
        }
        isLoading = false
    }
}

#Preview {
    NavigationView {
        MovieDetailView(result: IMDBService.SearchResult(
            imdbID: "tt0111161",
            Title: "The Shawshank Redemption",
            Year: "1994",
            Poster: "https://m.media-amazon.com/images/M/MV5BMDFkYTc0MGEtZmNhMC00ZDIzLWFmNTEtODM1ZmRlYWMwMWFmXkEyXkFqcGdeQXVyMTMxODk2OTU@._V1_SX300.jpg"
        ))
    }
}
