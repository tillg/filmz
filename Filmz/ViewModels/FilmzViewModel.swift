import Foundation
import SwiftUI

@MainActor
class FilmzViewModel: ObservableObject {
    private var imdbService: IMDBService?
    @Published var searchResults: [IMDBService.SearchResult] = []
    @Published var isSearching = false
    @Published var searchError: Error?
    @Published var canLoadMore = false
    @Published var serviceInitError: Error?
    
    private var currentQuery = ""
    private var currentPage = 1
    private var totalResults = 0
    
    init() {
        initializeService()
    }
    
    private func initializeService() {
        do {
            imdbService = try IMDBService()
        } catch {
            serviceInitError = error
        }
    }
    
    func search(_ query: String) {
        guard let imdbService else {
            searchError = serviceInitError ?? NSError(domain: "FilmzViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "IMDB Service not initialized"])
            return
        }
        
        guard !query.isEmpty else {
            searchResults = []
            canLoadMore = false
            return
        }
        
        // Reset state for new search
        currentQuery = query
        currentPage = 1
        searchResults = []
        
        isSearching = true
        searchError = nil
        
        Task {
            do {
                let state = try await imdbService.searchMovies(query)
                searchResults = state.results
                totalResults = state.totalResults
                currentPage = 1
                canLoadMore = searchResults.count < totalResults
                isSearching = false
            } catch {
                searchResults = []
                searchError = error
                canLoadMore = false
                isSearching = false
            }
        }
    }
    
    func loadMore() async {
        guard let imdbService, !isSearching && canLoadMore else { return }
        
        isSearching = true
        
        do {
            let nextPage = currentPage + 1
            let state = try await imdbService.searchMovies(currentQuery, page: nextPage)
            searchResults.append(contentsOf: state.results)
            currentPage = nextPage
            canLoadMore = searchResults.count < totalResults
        } catch {
            searchError = error
        }
        
        isSearching = false
    }
}