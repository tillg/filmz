import Foundation
import SwiftUI

@MainActor
class FilmzViewModel: ObservableObject {
    private let imdbService = IMDBService()
    @Published var searchResults: [IMDBService.SearchResult] = []
    @Published var isSearching = false
    @Published var searchError: Error?
    
    func search(_ query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        searchError = nil
        
        Task {
            do {
                searchResults = try await imdbService.searchMovies(query)
                isSearching = false
            } catch {
                searchResults = []
                searchError = error
                isSearching = false
            }
        }
    }
}