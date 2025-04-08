import CloudKit
import Foundation
import Logging
import SwiftUI

/// FilmStore is the main service that manages the film collection in the app.
/// It serves as a central point for all film-related operations and maintains the source of truth
/// for the UI layer. It handles:
/// - Loading and storing films using the provided repository
/// - Managing the in-memory film collection
/// - Sorting and filtering operations
/// - Synchronization with CloudKit through the repository
/// - Error handling and logging
@MainActor @Observable
class MyFilmStore {
    /// The current collection of films, published for SwiftUI updates
    private(set) var myFilms: [MyFilm] = []

    /// The genres we have in our myFilm-list
    private(set) var genres: [String] = []

    /// Indicates whether films are currently being loaded
    private(set) var isLoading: Bool = false

    /// Current status of iCloud connectivity, published for UI feedback
    private(set) var iCloudStatus: String = ""

    /// Current sort option for the film collection, automatically triggers resort on change
    var sortOption: SortOption = .dateAdded {
        didSet {
            sortFilms()
        }
    }

    /// The repository handling persistent storage operations
    private let myFilmRepository: MyFilmRepository

    /// Logger instance for debugging and error tracking
    private let logger = Logger(label: "FilmStore")

    /// Initialize the FilmStore with a FilmRepository
    /// - Parameter myFilmRepository: The repository to use for persistence. Defaults to CloudKitFilmRepository
    init(myFilmRepository: MyFilmRepository = MyFilmRepositoryCK()) {
        self.myFilmRepository = myFilmRepository
        logger.info("FilmStore initialized")
        checkICloudStatus()
        Task {
            await loadFilms()
        }
    }

    /// Loads all films from the myFilmRepository into memory
    private func loadFilms() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let loaded = try await myFilmRepository.fetchAllMyFilms()
            myFilms = loaded
            sortFilms()
            genres = await collectGenres(from: myFilms)  //Set(myFilms.flatMap { $0.imdbFilm?.genres ?? [""] }).sorted()
            logger.info(
                "Successfully loaded \(loaded.count) films from myFilmRepository")
        } catch {
            logger.error("loadFilms failed: \(error.localizedDescription)")
        }
    }

    // An async function to fetch and return a sorted set of genres from the films.
    func collectGenres(from films: [MyFilm]) async -> [String] {
        var genreSet = Set<String>()

        for film in films {
            do {
                // Await the asynchronous imdbFilm property.
                if let details = try await film.imdbFilm {
                    // Insert each genre into the set.
                    //                    for genre in details.genres {
                    //                        genreSet.insert(genre)
                    //                    }
                }
            } catch {
                logger.error(
                    "Error loading film details for film \(film.id): \(error)")
            }
        }

        // Return a sorted array of genres.
        return genreSet.sorted()
    }

    /// Sorts the films array based on the current sort option
    private func sortFilms() {
        myFilms = SortOption.sort(myFilms, by: sortOption)
    }

    /// Adds a new film to both the repository and local collection
    /// - Parameter film: The film to add
    /// - Note: This method will:
    ///   1. Check for duplicates
    ///   2. Download and create a CloudKit asset for the poster if needed
    ///   3. Save to repository
    ///   4. Update local collection
    func addMyFilm(_ myFilm: MyFilm) async {
        logger.info("FilmStore.addFilm: \(myFilm)")

        // Check if film already exists in memory
        if myFilms.contains(where: { $0.imdbId == myFilm.imdbId }) {
            logger.info(
                "Film already exists in library: ImdbId \(myFilm.imdbId))")
            return
        }

        // Create a mutable copy of the film
        let filmToAdd = myFilm

        // Delegate to repository
        do {
            try await myFilmRepository.addMyFilm(filmToAdd)
            myFilms.append(filmToAdd)
            sortFilms()
        } catch {
            logger.error(
                "Error adding film with IMDB Id\(myFilm.imdbId): \(error.localizedDescription)"
            )
        }
    }

    /// Removes a film from both the repository and local collection
    /// - Parameter film: The film to delete
    func deleteMyFilm(_ myFilm: MyFilm) async {
        do {
            try await myFilmRepository.deleteMyFilm(myFilm)
            myFilms.removeAll { $0.id == myFilm.id }
        } catch {
            logger.error(
                "Error deleting film with IMDB Id \(myFilm.imdbId): \(error.localizedDescription)"
            )
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
    func updateMyFilm(_ myFilm: MyFilm, with data: EditedFilmData) async {
        do {
            try await myFilmRepository.updateMyFilm(myFilm, with: data)

            // Reflect changes in the local array
            if let index = myFilms.firstIndex(where: { $0.id == myFilm.id }) {
                myFilms[index] = MyFilm(
                    id: myFilm.id,
                    imdbId: myFilm.imdbId,
                    recommendedBy: data.recommendedBy,
                    intendedAudience: data.intendedAudience,
                    watched: data.watched,
                    watchDate: data.watchDate,
                    streamingService: data.streamingService
                )
            }
        } catch {
            logger.error(
                "Error updating film with IMDB Id \(myFilm.imdbId): \(error.localizedDescription)"
            )
        }
    }
    
    /// Retrieves a film from the collection based on its unique identifier.
    /// - Parameter id: The unique identifier of the film.
    /// - Returns: The film if found, otherwise nil.
    func getFilmById(_ id: UUID) -> MyFilm? {
        return myFilms.first { $0.id == id }
    }

    /// Checks and updates the current iCloud account status
    /// - Note: This is used to provide feedback to the user about their iCloud connectivity
    private func checkICloudStatus() {
        CKContainer.default().accountStatus {
            [weak self] (status: CKAccountStatus, error: Error?) in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.iCloudStatus = "iCloud Available"
                case .noAccount:
                    self?.iCloudStatus = "No iCloud Account"
                case .restricted:
                    self?.iCloudStatus = "iCloud Restricted"
                case .couldNotDetermine:
                    self?.iCloudStatus =
                        "Could not determine iCloud status: \(error?.localizedDescription ?? "") "
                case .temporarilyUnavailable:
                    self?.iCloudStatus = "iCloud Temporarily Unavailable"
                @unknown default:
                    self?.iCloudStatus =
                        "Unknown iCloud status: \(status.rawValue)"
                }
                self?.logger.info(
                    "iCloud Status: \(self?.iCloudStatus ?? "Unknown")")
            }
        }
    }
}
