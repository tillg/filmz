import Foundation

struct Film: Identifiable, Codable {
    let id: UUID
    let title: String
    let year: String  // Changed from Int to String
    var genres: [String]
    var myRating: Int?  // 1-10
    var imdbRating: Double  // 1-10
    var posterUrl: String
    var description: String
    var trailerUrl: String?
    var country: String
    var language: String
    var releaseDate: Date
    var runtime: Int  // in minutes
    var plot: String
    
    // Sharing information
    var recommendedBy: String?
    var intendedAudience: AudienceType
    
    // Add new fields
    var watched: Bool
    var watchDate: Date?
    var streamingService: String?
    
    enum AudienceType: String, Codable {
        case alone = "Me alone"
        case partner = "Me and partner"
        case family = "Family"
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
        streamingService: String? = nil
    ) {
        self.id = id
        self.title = title
        self.year = year
        self.genres = genres
        self.imdbRating = imdbRating
        self.posterUrl = posterUrl
        self.description = description
        self.country = country
        self.language = language
        self.releaseDate = releaseDate
        self.runtime = runtime
        self.plot = plot
        self.recommendedBy = recommendedBy
        self.intendedAudience = intendedAudience
        self.watched = watched
        self.watchDate = watchDate
        self.streamingService = streamingService
    }
} 