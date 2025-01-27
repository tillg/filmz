import Foundation

actor IMDBService {
    private let apiKey: String
    private let baseUrl = "https://www.omdbapi.com/"
    
    init(apiKey: String? = nil) throws {
        if let providedKey = apiKey {
            self.apiKey = providedKey
        } else {
            self.apiKey = try Configuration.shared.string(forKey: "OMDB_API_KEY")
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
    }
    
    struct Rating: Codable {
        let Source: String
        let Value: String
    }
    
    func searchMovies(_ query: String, page: Int = 1) async throws -> SearchState {
        let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let searchQuery = cleanedQuery + "*"
        
        guard cleanedQuery.count >= 2 else {
            return SearchState(query: cleanedQuery, totalResults: 0, currentPage: page, results: [])
        }
        
        guard let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return SearchState(query: cleanedQuery, totalResults: 0, currentPage: page, results: [])
        }
        
        let url = URL(string: "\(baseUrl)?apikey=\(apiKey)&s=\(encodedQuery)&page=\(page)")!
        print("Search URL: \(url.absoluteString)")
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)
        
        if response.Response == "False" {
            throw NSError(
                domain: "IMDBService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: response.Error ?? "Movie not found!"]
            )
        }
        print("Number of entries found: \(response.totalResults ?? "0")")
        return SearchState(
            query: cleanedQuery,
            totalResults: Int(response.totalResults ?? "0") ?? 0,
            currentPage: page,
            results: response.Search ?? []
        )
    }
    
    func fetchMovieDetails(imdbId: String) async throws -> DetailResponse {
        guard let url = URL(string: "\(baseUrl)?apikey=\(apiKey)&i=\(imdbId)&plot=full") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(DetailResponse.self, from: data)
    }
} 
