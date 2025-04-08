import Foundation
import SwiftUI
import Logging

@MainActor
class FilmzSearchModel: ObservableObject {
    private var imdbService: ImdbFilmService?
    @Published var searchResults: [ImdbFilmService.ImdbSearchResult] = []
    @Published var isSearching = false
    @Published var searchError: Error?
    @Published var canLoadMore = false
    @Published var serviceInitError: Error?
    
    private var currentQuery = ""
    private var currentPage = 1
    private var totalResults = 0
    
    private let logger = Logger(label: "FilmzSearchModel")

    init() {
        logger.info("Initializing FilmzSearchModel")
        initializeService()
        logger.info("FilmzSearchModel initialized")

    }
    
    private func initializeService() {
        do {
            imdbService = try ImdbFilmService()
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
                let state = try await imdbService.searchFilms(query)
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
            let state = try await imdbService.searchFilms(currentQuery, page: nextPage)
            searchResults.append(contentsOf: state.results)
            currentPage = nextPage
            canLoadMore = searchResults.count < totalResults
        } catch {
            searchError = error
        }
        
        isSearching = false
    }
}
