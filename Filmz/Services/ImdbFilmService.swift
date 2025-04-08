import Foundation
import SwiftUI
import Logging

/// Service for interacting with the OMDB API
actor ImdbFilmService: ObservableObject {
    private let apiKey: String
    private let baseUrl = "https://www.omdbapi.com/"
    private let delay : UInt64 = 0 // Nanoseconds we sleep before loading from APIs
    private let logger = Logger(label: "ImdbFilmService")

    
    init(apiKey: String? = nil) throws {
        if let providedKey = apiKey {
            self.apiKey = providedKey
        } else {
            do {
                self.apiKey = try Configuration.shared.string(forKey: "OMDB_API_KEY")
            } catch {
                throw FilmzError.configurationMissing("OMDB_API_KEY")
            }
        }
    }
    
    struct SearchResponse: Codable {
        let Search: [ImdbSearchResult]?
        let totalResults: String?
        let Response: String
        let Error: String?
    }
    
    struct ImdbSearchResult: Codable, Identifiable {
        let imdbID: String
        let Title: String
        let Year: String
        let Poster: String
        var id: String { imdbID }
    }
    
    struct SearchState {
        let query: String
        let totalResults: Int
        let currentPage: Int
        let results: [ImdbSearchResult]
    }
    
    struct DetailResponse: Codable {
        let Title: String
        let Year: String
        let Rated: String
        let Released: String
        let Runtime: String
        let Genre: String
        let Plot: String
        let Language: String
        let Country: String
        let Poster: String
        let Ratings: [Rating]
        let imdbRating: String
        let imdbID: String
        
        var runtimeMinutes: Int {
            Int(Runtime.components(separatedBy: " ").first ?? "0") ?? 0
        }
        
        var imdbRatingDouble: Double {
            Double(imdbRating) ?? 0.0
        }
    }
    
    struct Rating: Codable {
        let Source: String
        let Value: String
    }
    
    func searchFilms(_ query: String, page: Int = 1) async throws -> SearchState {
        let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let searchQuery = cleanedQuery + "*"
        
        guard cleanedQuery.count >= 2 else {
            throw FilmzError.filmNotFound("Search query must be at least 2 characters")
        }
        
        guard let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw FilmzError.filmNotFound("Invalid search query")
        }
        
        guard let url = URL(string: "\(baseUrl)?apikey=\(apiKey)&s=\(encodedQuery)&page=\(page)") else {
            logger.error("Invalid URL: \(baseUrl)?apikey=\(apiKey)&s=\(encodedQuery)&page=\(page)")
            throw FilmzError.networkError(URLError(.badURL))
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(SearchResponse.self, from: data)
            
            if response.Response == "False" {
                throw FilmzError.filmNotFound(response.Error ?? "Movie not found!")
            }
            
            return SearchState(
                query: cleanedQuery,
                totalResults: Int(response.totalResults ?? "0") ?? 0,
                currentPage: page,
                results: response.Search ?? []
            )
        } catch let error as FilmzError {
            throw error
        } catch {
            throw FilmzError.networkError(error)
        }
    }
    
    func fetchFilmDetails(imdbId: String) async throws -> ImdbFilm {
        logger.info("fetchFilmDetails: Fetching details for film with ID \(imdbId)")
        guard !imdbId.isEmpty else {
            logger.error("IMDB ID cannot be empty")
            throw FilmzError.filmNotFound("IMDB ID cannot be empty")
        }
        
        guard let url = URL(string: "\(baseUrl)?apikey=\(apiKey)&i=\(imdbId)&plot=full") else {
            throw FilmzError.networkError(URLError(.badURL))
        }
        logger.info("GETting from url \(url)")
        try await Task.sleep(nanoseconds: delay) // Simulate network delay for development

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            decoder.userInfo[.rawJSONData] = data
            return try decoder.decode(ImdbFilm.self, from: data)
        } catch let error as DecodingError {
            throw FilmzError.decodingError(error)
        } catch {
            throw FilmzError.networkError(error)
        }
    }
}


#Preview {
    let batmanId = "tt0372784"
    let lassoId = "tt10986410"
    NavigationView {
        ImdbFilmDetailView(imdbId: batmanId)
    }
}
