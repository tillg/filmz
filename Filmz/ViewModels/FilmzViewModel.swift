import Foundation
import SwiftUI

@MainActor
class FilmzViewModel: ObservableObject {
    @Published var searchResults: [IMDBService.SearchResult] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    private let imdbService: IMDBService
    
    init(imdbService: IMDBService = IMDBService(apiKey: "1b5a29bf")) {
        self.imdbService = imdbService
    }
    
    func searchFilms(query: String) {
        // Reset results if query is too short
        guard query.count >= 3 else {
            searchResults = []
            return
        }
        
        Task {
            isSearching = true
            do {
                searchResults = try await imdbService.searchMovies(query: query)
                errorMessage = nil
            } catch {
                searchResults = []
                errorMessage = "Failed to search: \(error.localizedDescription)"
            }
            isSearching = false
        }
    }
}