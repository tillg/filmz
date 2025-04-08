import Foundation
import CloudKit
import Logging

let logger = Logger(label: "ImdbFilm")

extension CodingUserInfoKey {
    static let rawJSONData = CodingUserInfoKey(rawValue: "rawJSONData")!
}

/// Custom CKAsset coding to handle Codable conformance
private extension CKAsset {
    func encode() -> String? {
        return fileURL?.path
    }
    
    static func decode(from path: String) -> CKAsset? {
        return CKAsset(fileURL: URL(fileURLWithPath: path))
    }
}

private struct AnyCodingKey: CodingKey {
    var stringValue: String
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    var intValue: Int?
    
    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }
}

private extension KeyedDecodingContainer where Key == AnyCodingKey {
    func decode<T: Decodable>(_ type: T.Type, forKeys keys: [String]) throws -> T {
        for key in keys {
            if let codingKey = AnyCodingKey(stringValue: key), let value = try self.decodeIfPresent(T.self, forKey: codingKey) {
                return value
            }
        }
        throw DecodingError.keyNotFound(AnyCodingKey(stringValue: keys.first!)!, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Key not found among alternatives: \(keys)"))
    }

    func decodeIfPresent<T: Decodable>(_ type: T.Type, forKeys keys: [String]) -> T? {
        for key in keys {
            if let codingKey = AnyCodingKey(stringValue: key) {
                do {
                    if let value = try self.decodeIfPresent(T.self, forKey: codingKey) {
                        return value
                    }
                } catch {
                    // If decoding for this key fails, continue to the next key
                    continue
                }
            }
        }
        return nil
    }
}

/// Represents a film from IMDB
struct ImdbFilm: Identifiable, Codable {
    /// IMDB id
    let imdbId: String
    var id: String { imdbId }
    
    /// Title of the film
    let title: String
    
    /// Release year of the film. Needs to be a string as it can be a range, i.e. "2001-2007"
    let year: String
    
    /// List of genres associated with the film
    var genres: [String]
    
    
    /// IMDB rating of the film (0-10)
    private var _imdbRating: Double
    var imdbRating: Double {
        get { _imdbRating }
        set {
            assert((0...10).contains(newValue), "IMDB rating must be between 0 and 10")
            _imdbRating = newValue
        }
    }
    
    /// URL of the film's poster image
    var posterUrl: String
    
    /// Optional URL to the film's trailer
    var trailerUrl: String?
    
    /// Country of origin
    var country: String
    
    /// Primary language of the film
    var language: String
    
    /// Runtime in minutes
    var runtime: String
    
    /// Detailed plot summary
    var plot: String

    enum CodingKeys: String, CodingKey {
        case imdbId, title, year, genres, posterUrl,  description, trailerUrl
        case country, language, releaseDate, plot, dateAdded
        case imdbRating = "_imdbRating"
        case runtime = "_runtime"
    }
    
    // Initializes a new Film instance from a decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        imdbId = try container.decode(String.self, forKeys: ["imdbId", "imdbID"])
        title = try container.decode(String.self, forKeys: ["title", "Title"])
        year =  container.decodeIfPresent(String.self, forKeys: ["year", "Year"]) ?? ""
        
        if let genreArray = try? container.decode([String].self, forKeys: ["genres", "Genres", "genre", "Genre"]) {
            genres = genreArray
        } else {
            let genreString =  container.decodeIfPresent(String.self, forKeys: ["genres", "Genres", "genre", "Genre"]) ?? ""
            genres = genreString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        
        posterUrl =  container.decodeIfPresent(String.self, forKeys: ["posterUrl", "PosterUrl", "Poster"]) ?? ""
        trailerUrl =  container.decodeIfPresent(String.self, forKeys: ["trailerUrl", "TrailerUrl"]) ?? ""
        country =  container.decodeIfPresent(String.self, forKeys: ["country", "Country"]) ?? ""
        language =  container.decodeIfPresent(String.self, forKeys: ["language", "Language"]) ?? ""
        runtime =  container.decodeIfPresent(String.self, forKeys: ["_runtime", "runtime", "Runtime"]) ?? ""
        //_imdbRating =  container.decodeIfPresent(Double.self, forKeys: ["_imdbRating", "imdbRating", "IMDBRating"]) ?? 0.0
        if let imdbRatingString = try? container.decode(String.self, forKeys: ["_imdbRating", "imdbRating", "IMDBRating"]) {
            _imdbRating = Double(imdbRatingString) ?? 0.0
        } else {
            _imdbRating = 0.0
        }
        plot =  container.decodeIfPresent(String.self, forKeys: ["plot", "Plot"]) ?? ""
    }
    
    // Encodes the Film instance to an encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(imdbId, forKey: .imdbId)
        try container.encode(title, forKey: .title)
        try container.encode(year, forKey: .year)
        try container.encode(genres, forKey: .genres)
        try container.encode(_imdbRating, forKey: .imdbRating)
        try container.encode(posterUrl, forKey: .posterUrl)
        try container.encodeIfPresent(trailerUrl, forKey: .trailerUrl)
        try container.encode(country, forKey: .country)
        try container.encode(language, forKey: .language)
        try container.encode(runtime, forKey: .runtime)
        try container.encode(plot, forKey: .plot)
    }
    
    // Initializes a new Film instance with the provided parameters
    init(
        imdbId: String,
        title: String,
        year: String,
        genres: [String],
        imdbRating: Double,
        posterUrl: String,
        description: String,
        trailerUrl: String? = nil,
        country: String,
        language: String,
        releaseDate: Date,
        runtime: String,
        plot: String,
        recommendedBy: String? = nil
    ) {
        self.imdbId = imdbId
        self.title = title
        self.year = year
        self.genres = genres
        self._imdbRating = imdbRating
        self.posterUrl = posterUrl
        self.trailerUrl = trailerUrl
        self.country = country
        self.language = language
        self.runtime = runtime
        self.plot = plot
    }

}
