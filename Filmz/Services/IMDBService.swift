import Foundation

/// Service for interacting with the OMDB API
actor IMDBService {
    private let apiKey: String
    private let baseUrl = "https://www.omdbapi.com/"
    
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
        let Search: [SearchResult]?
        let totalResults: String?
        let Response: String
        let Error: String?
    }
    
    struct SearchResult: Codable, Identifiable {
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
        let results: [SearchResult]
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
    
    func searchMovies(_ query: String, page: Int = 1) async throws -> SearchState {
        let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let searchQuery = cleanedQuery + "*"
        
        guard cleanedQuery.count >= 2 else {
            throw FilmzError.filmNotFound("Search query must be at least 2 characters")
        }
        
        guard let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw FilmzError.filmNotFound("Invalid search query")
        }
        
        guard let url = URL(string: "\(baseUrl)?apikey=\(apiKey)&s=\(encodedQuery)&page=\(page)") else {
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
    
    func fetchMovieDetails(imdbId: String) async throws -> DetailResponse {
        guard !imdbId.isEmpty else {
            throw FilmzError.filmNotFound("IMDB ID cannot be empty")
        }
        
        guard let url = URL(string: "\(baseUrl)?apikey=\(apiKey)&i=\(imdbId)&plot=full") else {
            throw FilmzError.networkError(URLError(.badURL))
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode(DetailResponse.self, from: data)
        } catch let error as DecodingError {
            throw FilmzError.decodingError(error)
        } catch {
            throw FilmzError.networkError(error)
        }
    }
}
