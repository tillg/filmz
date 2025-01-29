import Foundation
import OSLog
import SwiftUI

/// A domain-oriented actor that centralizes film-related business logic:
///  - Checking for duplicates
///  - Fetching extended film details from IMDBService
///  - Storing/persisting films through the FilmRepository
///
/// This manager prevents the Views (AddFilmView, SearchFilmsView, etc.)
/// from directly handling business rules or data-layer operations.
actor FilmManager {
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "FilmManager")
    
    /// IMDBService is already an actor; we store an instance for making network calls
    private let imdbService: IMDBService
    
    /// The film repository for persisting data (e.g., CloudKitFilmRepository)
    private let repository: FilmRepository
    
    /// An in-memory cache or source of truth for loaded films, if desired.
    /// Alternatively, you could always fetch from the repository directly.
    private(set) var allFilms: [Film] = []
    
    init(imdbService: IMDBService? = nil,
         repository: FilmRepository) {
        // If no imdbService was supplied, we try to initialize a default one.
        if let existingService = imdbService {
            self.imdbService = existingService
        } else {
            do {
                self.imdbService = try IMDBService()
            } catch {
                fatalError("Failed to initialize IMDBService: \\(error.localizedDescription)")
            }
        }
        self.repository = repository
        
        logger.info("FilmManager initialized")
    }
    
    // MARK: - Public Methods
    
    /// Loads all films from the repository into local memory (allFilms).
    /// Call this once at startup or refresh as needed.
    func loadAllFilms() async throws {
        do {
            let loadedFilms = try await repository.fetchAllFilms()
            allFilms = loadedFilms
            logger.info("Loaded \\(loadedFilms.count) films from repository into FilmManager")
        } catch {
            logger.error("loadAllFilms failed: \\(error.localizedDescription)")
            throw error
        }
    }
    
    /// High-level method to add a film by searching IMDB or using partial info,
    /// then storing it in the repository. Views can call this instead of
    /// duplicating logic in AddFilmView, etc.
    ///
    /// - Parameters:
    ///   - searchResult: The partial search result from IMDB
    ///   - recommendedBy: Who recommended
    ///   - watched: Watch status
    ///   - watchDate: Date watched (if any)
    ///   - streamingService: Which service it's on
    ///   - audience: Intended audience
    /// - Returns: The fully created `Film`
    func addFilm(from searchResult: IMDBService.SearchResult,
                 recommendedBy: String,
                 watched: Bool,
                 watchDate: Date? = nil,
                 streamingService: String? = nil,
                 audience: Film.AudienceType = .alone) async throws -> Film {
        
        // 1. Check for duplicates in the local allFilms array
        let lowerTitle = searchResult.Title.lowercased()
        if allFilms.contains(where: { $0.title.lowercased() == lowerTitle && $0.year == searchResult.Year }) {
            logger.info("Duplicate film attempt: \\(searchResult.Title) (\\(searchResult.Year))")
            throw FilmzError.duplicateFilm(searchResult.Title)
        }
        
        // 2. (Optional) fetch extended details from IMDB if desired
        //    or we can do it after we create a minimal film. Up to your workflow.
        let detailResponse = try await imdbService.fetchMovieDetails(imdbId: searchResult.imdbID)
        
        // 3. Construct a complete Film object
        let film = Film(
            title: detailResponse.Title,
            year: detailResponse.Year,
            genres: detailResponse.Genre.components(separatedBy: ", "),
            imdbRating: Double(detailResponse.imdbRating) ?? 0.0,
            posterUrl: detailResponse.Poster,
            description: detailResponse.Plot,
            country: detailResponse.Country,
            language: detailResponse.Language,
            releaseDate: Date(), // If detailResponse has a more accurate date, parse it
            runtime: detailResponse.runtimeMinutes,
            plot: detailResponse.Plot,
            recommendedBy: recommendedBy,
            intendedAudience: audience,
            watched: watched,
            watchDate: watched ? watchDate : nil,
            streamingService: watched ? streamingService : nil
        )
        
        // 4. Persist the film in the repository
        try await repository.addFilm(film)
        
        // 5. Update local memory
        allFilms.append(film)
        logger.info("Successfully added film \\(film.title) to repository & local store.")
        
        return film
    }
    
    /// A more generic add method that doesn't rely on search results.
    /// For instance, you might have a partially filled Film struct from another source.
    func addFilm(_ film: Film) async throws {
        // Check for duplicates locally
        let lowerTitle = film.title.lowercased()
        if allFilms.contains(where: { $0.title.lowercased() == lowerTitle && $0.year == film.year }) {
            logger.info("Duplicate film attempt: \\(film.title) (\\(film.year))")
            throw FilmzError.duplicateFilm(film.title)
        }
        
        // If no duplicate, store it
        try await repository.addFilm(film)
        allFilms.append(film)
    }
    
    /// Fetches detailed info for a film from the IMDBService
    /// This can be called by e.g. `MovieDetailView`, so that the View isn't
    /// interacting with IMDBService directly.
    func fetchFilmDetails(imdbId: String) async throws -> IMDBService.DetailResponse {
        return try await imdbService.fetchMovieDetails(imdbId: imdbId)
    }
    
    /// Example method for updating a film (like watch status, streaming service, etc.).
    /// You can expand or reuse the existing `EditedFilmData` approach here as well.
    func updateFilm(_ film: Film, with data: EditedFilmData) async throws {
        try await repository.updateFilm(film, with: data)
        // Also update in local memory
        if let index = allFilms.firstIndex(where: { $0.id == film.id }) {
            var updated = allFilms[index]
            updated.genres = data.genres
            updated.recommendedBy = data.recommendedBy
            updated.intendedAudience = data.intendedAudience
            updated.watched = data.watched
            updated.watchDate = data.watchDate
            updated.streamingService = data.streamingService
            allFilms[index] = updated
        }
    }
    
    /// Delete a film from the repository & local memory
    func deleteFilm(_ film: Film) async throws {
        try await repository.deleteFilm(film)
        allFilms.removeAll { $0.id == film.id }
    }
}