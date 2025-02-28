import Foundation
import OSLog
import SwiftUI
import CloudKit

/// FilmStore is the main service that manages the film collection in the app.
/// It serves as a central point for all film-related operations and maintains the source of truth
/// for the UI layer. It handles:
/// - Loading and storing films using the provided repository
/// - Managing the in-memory film collection
/// - Sorting and filtering operations
/// - Synchronization with CloudKit through the repository
/// - Error handling and logging
@MainActor
class FilmStore: ObservableObject {
    /// The current collection of films, published for SwiftUI updates
    @Published private(set) var films: [Film] = []

    /// Current status of iCloud connectivity, published for UI feedback
    @Published private(set) var iCloudStatus: String = ""

    /// Current sort option for the film collection, automatically triggers resort on change
    @Published var sortOption: SortOption = .dateAdded {
        didSet {
            sortFilms()
        }
    }

    /// The repository handling persistent storage operations
    private let repository: FilmRepository

    /// Logger instance for debugging and error tracking
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "FilmStore")

    /// Initialize the FilmStore with a FilmRepository
    /// - Parameter repository: The repository to use for persistence. Defaults to CloudKitFilmRepository
    init(repository: FilmRepository = CloudKitFilmRepository()) {
        self.repository = repository
        logger.info("FilmStore initialized")

        checkICloudStatus()

        Task {
            await loadFilms()
        }
    }

    /// Loads all films from the repository into memory
    private func loadFilms() async {
        do {
            let loaded = try await repository.fetchAllFilms()
            films = loaded
            sortFilms()
            logger.info("Successfully loaded \\(loaded.count) films from repository")
        } catch {
            logger.error("loadFilms failed: \\(error.localizedDescription)")
        }
    }

    /// Sorts the films array based on the current sort option
    private func sortFilms() {
        films = SortOption.sort(films, by: sortOption)
    }

    /// Adds a new film to both the repository and local collection
    /// - Parameter film: The film to add
    /// - Note: This method will:
    ///   1. Check for duplicates
    ///   2. Download and create a CloudKit asset for the poster if needed
    ///   3. Save to repository
    ///   4. Update local collection
    func addFilm(_ film: Film) async {
        // Check if film already exists in memory
        if films.contains(where: { $0.title.lowercased() == film.title.lowercased() && $0.year == film.year }) {
            logger.info("Film already exists in library: \\(film.title) (\\(film.year))")
            return
        }

        // Create a mutable copy of the film
        let filmToAdd = film

        // Delegate to repository
        do {
            try await repository.addFilm(filmToAdd)
            films.append(filmToAdd)
            sortFilms()
        } catch {
            logger.error("Error adding film \\(film.title): \\(error.localizedDescription)")
        }
    }

    /// Removes a film from both the repository and local collection
    /// - Parameter film: The film to delete
    func deleteFilm(_ film: Film) async {
        do {
            try await repository.deleteFilm(film)
            films.removeAll { $0.id == film.id }
        } catch {
            logger.error("Error deleting film \\(film.title): \\(error.localizedDescription)")
        }
    }

    /// Updates an existing film with new data
    /// - Parameters:
    ///   - film: The film to update
    ///   - data: The new data to apply
    /// - Note: This method will:
    ///   1. Create a CloudKit asset for the poster if needed
    ///   2. Update the repository
    ///   3. Update the local collection
    func updateFilm(_ film: Film, with data: EditedFilmData) async {
        do {

            try await repository.updateFilm(film, with: data)

            // Reflect changes in the local array
            if let index = films.firstIndex(where: { $0.id == film.id }) {
                films[index] = Film(
                    id: film.id,
                    title: film.title,
                    year: film.year,
                    genres: data.genres,
                    imdbRating: film.imdbRating,
                    posterUrl: film.posterUrl,
                    description: film.description,
                    country: film.country,
                    language: film.language,
                    releaseDate: film.releaseDate,
                    runtime: film.runtime,
                    plot: film.plot,
                    recommendedBy: data.recommendedBy,
                    intendedAudience: data.intendedAudience,
                    watched: data.watched,
                    watchDate: data.watchDate,
                    streamingService: data.streamingService,
                    dateAdded: film.dateAdded
                )
            }
        } catch {
            logger.error("Error updating film \\(film.title): \\(error.localizedDescription)")
        }
    }

    /// Checks and updates the current iCloud account status
    /// - Note: This is used to provide feedback to the user about their iCloud connectivity
    private func checkICloudStatus() {
        CKContainer.default().accountStatus { [weak self] (status: CKAccountStatus, error: Error?) in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.iCloudStatus = "iCloud Available"
                case .noAccount:
                    self?.iCloudStatus = "No iCloud Account"
                case .restricted:
                    self?.iCloudStatus = "iCloud Restricted"
                case .couldNotDetermine:
                    self?.iCloudStatus = "Could not determine iCloud status: \\(error?.localizedDescription ?? \"\")"
                case .temporarilyUnavailable:
                    self?.iCloudStatus = "iCloud Temporarily Unavailable"
                @unknown default:
                    self?.iCloudStatus = "Unknown iCloud status: \\(status.rawValue)"
                }
                self?.logger.debug("iCloud Status: \\(self?.iCloudStatus ?? \"\")")
                print("iCloud Status: \\(self?.iCloudStatus ?? \"\")")
            }
        }
    }
}
