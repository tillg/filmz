import Foundation

actor IMDBService {
    private let apiKey: String
    private let baseUrl = "https://www.omdbapi.com/"
    
    init(apiKey: String = "YOUR_API_KEY") {
        self.apiKey = apiKey
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
    
    func searchMovies(query: String) async throws -> [SearchResult] {
        // Clean up and prepare the search query
        let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanedQuery.isEmpty,
              let encodedQuery = cleanedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseUrl)?apikey=\(apiKey)&s=\(encodedQuery)") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)
        
        if response.Response == "False" {
            throw NSError(
                domain: "IMDBService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: response.Error ?? "No results found"]
            )
        }
        
        return response.Search ?? []
    }
    
    func fetchMovieDetails(imdbId: String) async throws -> DetailResponse {
        guard let url = URL(string: "\(baseUrl)?apikey=\(apiKey)&i=\(imdbId)&plot=full") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(DetailResponse.self, from: data)
    }
} 