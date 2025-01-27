import Foundation

enum FilmzError: LocalizedError {
    case configurationMissing(String)
    case networkError(Error)
    case invalidAPIKey
    case filmNotFound(String)
    case duplicateFilm(String)
    case cloudKitError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .configurationMissing(let key):
            return "Configuration missing: \(key)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidAPIKey:
            return "Invalid OMDB API key"
        case .filmNotFound(let title):
            return "Film not found: \(title)"
        case .duplicateFilm(let title):
            return "Film already exists: \(title)"
        case .cloudKitError(let error):
            return "CloudKit error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
