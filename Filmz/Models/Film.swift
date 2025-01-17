import Foundation

struct Film: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var year: Int
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
    
    enum AudienceType: String, Codable {
        case alone = "Me alone"
        case partner = "Me and partner"
        case family = "Family"
    }
} 