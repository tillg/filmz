import Foundation
import CloudKit

/// Custom CKAsset coding to handle Codable conformance
private extension CKAsset {
    func encode() -> String? {
        return fileURL?.path
    }
    
    static func decode(from path: String) -> CKAsset? {
        return CKAsset(fileURL: URL(fileURLWithPath: path))
    }
}

/// Represents a film in the application with its metadata and user preferences
struct MyFilm: Identifiable, Codable {
    // Shared IMDB film service instance to load film details only once
    private static let imdbFilmService: ImdbFilmService = {
        do {
            return try ImdbFilmService()
        } catch {
            fatalError("Failed to initialize ImdbFilmService: \(error)")
        }
    }()
    
    /// Unique identifier for the film
    let id: UUID
    
    /// IMDB id
    let imdbId: String?
    
    /// Read-only attribute to get detailed IMDB film information loaded from ImdbFilmService
    var imdbFilm: ImdbFilm? {
        get async throws {
            guard let imdbId = imdbId else {
                return nil
            }
            return try await MyFilm.imdbFilmService.fetchFilmDetails(imdbId: imdbId)
        }
    }
    
    /// User's rating of the film (1-10)
    private var _myRating: Int?
    var myRating: Int? {
        get { _myRating }
        set {
            if let rating = newValue {
                assert((0...10).contains(rating), "Rating must be between 0 and 10")
            }
            _myRating = newValue
        }
    }
    
    /// Date when the film was added to the user's collection
    let dateAdded: Date
        
    /// Person who recommended the film
    var recommendedBy: String?
    
    /// Intended viewing audience
    var intendedAudience: AudienceType
    
    // MARK: - Viewing Status
    
    /// Whether the film has been watched
    var watched: Bool
    
    /// Date when the film was watched
    var watchDate: Date?
    
    /// Streaming service where the film is available
    var streamingService: String?
    
    enum AudienceType: String, Codable {
        case alone = "Me alone"
        case partner = "Me and partner"
        case family = "Family"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, imdbId, dateAdded
        case recommendedBy, intendedAudience, watched, watchDate, streamingService
        case myRating = "_myRating"
    }
    
    // Initializes a new Film instance from a decoder
     init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        imdbId = try container.decode(String.self, forKey: .imdbId)
        _myRating = try container.decodeIfPresent(Int.self, forKey: .myRating)
        dateAdded = try container.decode(Date.self, forKey: .dateAdded)
        recommendedBy = try container.decodeIfPresent(String.self, forKey: .recommendedBy)
        intendedAudience = try container.decode(AudienceType.self, forKey: .intendedAudience)
        watched = try container.decode(Bool.self, forKey: .watched)
        watchDate = try container.decodeIfPresent(Date.self, forKey: .watchDate)
        streamingService = try container.decodeIfPresent(String.self, forKey: .streamingService)
    }
    
    // Encodes the Film instance to an encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(_myRating, forKey: .myRating)
        try container.encode(dateAdded, forKey: .dateAdded)
        try container.encodeIfPresent(recommendedBy, forKey: .recommendedBy)
        try container.encode(intendedAudience, forKey: .intendedAudience)
        try container.encode(watched, forKey: .watched)
        try container.encodeIfPresent(watchDate, forKey: .watchDate)
        try container.encodeIfPresent(streamingService, forKey: .streamingService)
    }
    
    // Initializes a new Film instance with the provided parameters
    init(
        id: UUID = UUID(),
        imdbId: String? = nil,
        recommendedBy: String? = nil,
        intendedAudience: AudienceType? = nil,
        watched: Bool = false,
        watchDate: Date? = nil,
        streamingService: String? = nil,
        dateAdded : Date? = Date()
    ) {
        self.id = id
        self.imdbId = imdbId
        self.recommendedBy = recommendedBy
        self.intendedAudience = intendedAudience ?? .alone
        self.watched = watched
        self.watchDate = watchDate
        self.streamingService = streamingService
        self.dateAdded = dateAdded ?? Date()
    }
    
    // Creates a new Film instance from an IMDBService.SearchResult
    static func create(from result: ImdbFilmService.ImdbSearchResult,
                      recommendedBy: String? = nil,
                      intendedAudience: AudienceType = .alone,
                      watched: Bool = false,
                      watchDate: Date? = nil,
                      streamingService: String? = nil) -> MyFilm {
        MyFilm(
            imdbId: result.imdbID,
            recommendedBy: recommendedBy,
            intendedAudience: intendedAudience,
            watched: watched,
            watchDate: watchDate,
            streamingService: streamingService
        )
    }
}
