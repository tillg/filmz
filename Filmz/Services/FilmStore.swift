import Foundation
import OSLog
import SwiftUI
import CloudKit

@MainActor
class FilmStore: ObservableObject {
    @Published private(set) var films: [Film] = []
    @Published private(set) var iCloudStatus: String = ""
    @Published var sortOption: SortOption = .dateAdded {
        didSet {
            sortFilms()
        }
    }
    
    private let repository: FilmRepository
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "FilmStore")
    
    /// Initialize the FilmStore with a FilmRepository. Default is CloudKitFilmRepository.
    init(repository: FilmRepository = CloudKitFilmRepository()) {
        self.repository = repository
        logger.info("FilmStore initialized")
        
        // Optionally, check iCloud account status if needed for user feedback
        checkICloudStatus()
        
        // Load existing films asynchronously
        Task {
            await loadFilms()
        }
    }
    
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
    
    private func sortFilms() {
        films = SortOption.sort(films, by: sortOption)
    }
    
    func addFilm(_ film: Film) async {
        // Check if film already exists in memory
        if films.contains(where: { $0.title.lowercased() == film.title.lowercased() && $0.year == film.year }) {
            logger.info("Film already exists in library: \\(film.title) (\\(film.year))")
            return
        }
        
        // Create a mutable copy of the film
        var filmToAdd = film
        
        // Download and create CloudKit asset for the poster if not already present
        if filmToAdd.posterAsset == nil {
            do {
                if let posterAsset = try await PosterImageCache.shared.downloadAndCreateAsset(from: film.posterUrl) {
                    filmToAdd.posterAsset = posterAsset
                }
            } catch {
                logger.error("Failed to create poster asset: \\(error.localizedDescription)")
            }
        }
        
        // Delegate to repository
        do {
            try await repository.addFilm(filmToAdd)
            films.append(filmToAdd)
            sortFilms()
        } catch {
            logger.error("Error adding film \\(film.title): \\(error.localizedDescription)")
        }
    }
    
    func deleteFilm(_ film: Film) async {
        do {
            try await repository.deleteFilm(film)
            films.removeAll { $0.id == film.id }
        } catch {
            logger.error("Error deleting film \\(film.title): \\(error.localizedDescription)")
        }
    }
    
    func updateFilm(_ film: Film, with data: EditedFilmData) async {
        do {
            // If we're updating the film and it doesn't have a poster asset yet, create one
            var updatedFilm = film
            if film.posterAsset == nil {
                if let posterAsset = try await PosterImageCache.shared.downloadAndCreateAsset(from: film.posterUrl) {
                    updatedFilm.posterAsset = posterAsset
                }
            }
            
            try await repository.updateFilm(updatedFilm, with: data)
            
            // Reflect changes in the local array
            if let index = films.firstIndex(where: { $0.id == film.id }) {
                films[index] = Film(
                    id: film.id,
                    title: film.title,
                    year: film.year,
                    genres: data.genres,
                    imdbRating: film.imdbRating,
                    posterUrl: film.posterUrl,
                    posterAsset: updatedFilm.posterAsset,
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
    
    /// Example: check iCloud status for user-facing logic
    private func checkICloudStatus() {
        // Provide explicit type annotations for the closure parameters
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
                self?.logger.info("iCloud Status: \\(self?.iCloudStatus ?? \"\")")
            }
        }
    }
}