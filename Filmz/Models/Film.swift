import Foundation

/// Represents a film in the application with its metadata and user preferences
struct Film: Identifiable, Codable {
    /// Unique identifier for the film
    let id: UUID
    
    /// Title of the film
    let title: String
    
    /// Release year of the film. Needs to be a string as it can be a range, i.e. "2001-2007"
    let year: String
    
    /// List of genres associated with the film
    var genres: [String]
    
    /// User's rating of the film (1-10)
    private var _myRating: Int?
    var myRating: Int? {
        get { _myRating }
        set {
            if let rating = newValue {
                assert((1...10).contains(rating), "Rating must be between 1 and 10")
            }
            _myRating = newValue
        }
    }
    
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
    
    /// Brief description of the film
    var description: String
    
    /// Optional URL to the film's trailer
    var trailerUrl: String?
    
    /// Country of origin
    var country: String
    
    /// Primary language of the film
    var language: String
    
    /// Official release date
    var releaseDate: Date
    
    /// Runtime in minutes
    private var _runtime: Int
    var runtime: Int {
        get { _runtime }
        set {
            assert(newValue > 0, "Runtime must be positive")
            _runtime = newValue
        }
    }
    
    /// Detailed plot summary
    var plot: String
    
    /// Date when the film was added to the user's collection
    let dateAdded: Date
    
    // MARK: - Sharing Information
    
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
        case id, title, year, genres, posterUrl, description, trailerUrl
        case country, language, releaseDate, plot, dateAdded
        case recommendedBy, intendedAudience, watched, watchDate, streamingService
        case myRating = "_myRating"
        case imdbRating = "_imdbRating"
        case runtime = "_runtime"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        year = try container.decode(String.self, forKey: .year)
        genres = try container.decode([String].self, forKey: .genres)
        _myRating = try container.decodeIfPresent(Int.self, forKey: .myRating)
        _imdbRating = try container.decode(Double.self, forKey: .imdbRating)
        posterUrl = try container.decode(String.self, forKey: .posterUrl)
        description = try container.decode(String.self, forKey: .description)
        trailerUrl = try container.decodeIfPresent(String.self, forKey: .trailerUrl)
        country = try container.decode(String.self, forKey: .country)
        language = try container.decode(String.self, forKey: .language)
        releaseDate = try container.decode(Date.self, forKey: .releaseDate)
        _runtime = try container.decode(Int.self, forKey: .runtime)
        plot = try container.decode(String.self, forKey: .plot)
        dateAdded = try container.decode(Date.self, forKey: .dateAdded)
        recommendedBy = try container.decodeIfPresent(String.self, forKey: .recommendedBy)
        intendedAudience = try container.decode(AudienceType.self, forKey: .intendedAudience)
        watched = try container.decode(Bool.self, forKey: .watched)
        watchDate = try container.decodeIfPresent(Date.self, forKey: .watchDate)
        streamingService = try container.decodeIfPresent(String.self, forKey: .streamingService)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(year, forKey: .year)
        try container.encode(genres, forKey: .genres)
        try container.encodeIfPresent(_myRating, forKey: .myRating)
        try container.encode(_imdbRating, forKey: .imdbRating)
        try container.encode(posterUrl, forKey: .posterUrl)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(trailerUrl, forKey: .trailerUrl)
        try container.encode(country, forKey: .country)
        try container.encode(language, forKey: .language)
        try container.encode(releaseDate, forKey: .releaseDate)
        try container.encode(_runtime, forKey: .runtime)
        try container.encode(plot, forKey: .plot)
        try container.encode(dateAdded, forKey: .dateAdded)
        try container.encodeIfPresent(recommendedBy, forKey: .recommendedBy)
        try container.encode(intendedAudience, forKey: .intendedAudience)
        try container.encode(watched, forKey: .watched)
        try container.encodeIfPresent(watchDate, forKey: .watchDate)
        try container.encodeIfPresent(streamingService, forKey: .streamingService)
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        year: String,
        genres: [String],
        imdbRating: Double,
        posterUrl: String,
        description: String,
        country: String,
        language: String,
        releaseDate: Date,
        runtime: Int,
        plot: String,
        recommendedBy: String?,
        intendedAudience: AudienceType,
        watched: Bool = false,
        watchDate: Date? = nil,
        streamingService: String? = nil,
        dateAdded: Date = Date()  // Default to current date
    ) {
        self.id = id
        self.title = title
        self.year = year
        self.genres = genres
        self._imdbRating = imdbRating
        self.posterUrl = posterUrl
        self.description = description
        self.country = country
        self.language = language
        self.releaseDate = releaseDate
        self._runtime = runtime
        self.plot = plot
        self.recommendedBy = recommendedBy
        self.intendedAudience = intendedAudience
        self.watched = watched
        self.watchDate = watchDate
        self.streamingService = streamingService
        self.dateAdded = dateAdded
    }
}
