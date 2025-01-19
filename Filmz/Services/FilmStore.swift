import CloudKit
import Foundation
import UIKit

@MainActor
class FilmStore: ObservableObject {
    @Published private(set) var films: [Film] = []
    @Published private(set) var iCloudStatus: String = ""
    private let container: CKContainer
    private let database: CKDatabase
    
    init() {
        container = CKContainer(identifier: "iCloud.com.grtnr.Filmz")
        database = container.privateCloudDatabase
        
        // Check CloudKit availability
        Task {
            do {
                let accountStatus = try await container.accountStatus()
                print("CloudKit account status: \(accountStatus.rawValue)")
                
                switch accountStatus {
                case .available:
                    print("CloudKit is available, loading films...")
                    await loadFilms()
                case .noAccount:
                    print("No iCloud account found. Please sign in to iCloud in Settings")
                case .restricted:
                    print("iCloud access is restricted")
                case .couldNotDetermine:
                    print("Could not determine iCloud account status")
                @unknown default:
                    print("Unknown iCloud account status")
                }
            } catch {
                print("Failed to check CloudKit status: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadFilms() async {
        print("Starting to load films...")
        
        do {
            // Use a simple query with no predicate
            let query = CKQuery(recordType: "Film", predicate: .init(value: true))
            let descriptor = NSSortDescriptor(key: "title", ascending: true)
            query.sortDescriptors = [descriptor]
            
            let (matchResults, _) = try await database.records(matching: query)
            print("Found \(matchResults.count) records in CloudKit")
            
            let loadedFilms = matchResults.compactMap { result -> Film? in
                do {
                    let record = try result.1.get()
                    print("Processing record: \(record.recordID)")
                    return Film.from(record: record)
                } catch {
                    print("Failed to process record: \(error)")
                    return nil
                }
            }
            
            films = loadedFilms
            print("Successfully loaded \(loadedFilms.count) films")
        } catch {
            print("Failed to fetch films with error: \(error)")
            if let ckError = error as? CKError {
                print("CKError code: \(ckError.code.rawValue)")
                print("CKError description: \(ckError.localizedDescription)")
                if let serverMessage = ckError.errorUserInfo[NSLocalizedDescriptionKey] as? String {
                    print("Server message: \(serverMessage)")
                }
            }
        }
    }
    
    func addFilm(_ film: Film) async {
        log("Starting to add film: \(film.title)")
        let record = CKRecord(recordType: "Film")
        
        // Set all fields
        record["title"] = film.title
        record["year"] = film.year
        record["genres"] = film.genres
        record["posterUrl"] = film.posterUrl
        record["description"] = film.description
        record["country"] = film.country
        record["language"] = film.language
        record["runtime"] = film.runtime
        record["plot"] = film.plot
        record["recommendedBy"] = film.recommendedBy ?? ""
        record["intendedAudience"] = film.intendedAudience.rawValue
        record["watched"] = film.watched
        record["watchDate"] = film.watchDate
        record["streamingService"] = film.streamingService
        
        do {
            let savedRecord = try await database.save(record)
            log("Successfully saved record with ID: \(savedRecord.recordID)")
            
            await MainActor.run {
                self.films.append(film)
            }
            
            // Check iCloud status after saving
            checkICloudStatus()
            
        } catch let error as CKError {
            log("CloudKit error saving film", error: error)
            switch error.code {
            case .notAuthenticated:
                log("User is not authenticated with iCloud")
            case .networkFailure:
                log("Network connection failed")
            case .networkUnavailable:
                log("Network is unavailable")
            case .serverResponseLost:
                log("Server response was lost")
            case .serverRejectedRequest:
                log("Server rejected the request")
            default:
                log("Other CloudKit error: \(error.localizedDescription)")
            }
        } catch {
            log("Non-CloudKit error saving film", error: error)
        }
    }
    
    func deleteFilm(_ film: Film) async {
        // First find the record ID
        let query = CKQuery(
            recordType: "Film",
            predicate: NSPredicate(format: "title == %@ AND year == %@", film.title, film.year)
        )
        
        do {
            let records = try await database.records(matching: query)
            if let record = try records.matchResults.first?.1.get() {
                try await database.deleteRecord(withID: record.recordID)
                films.removeAll { $0.id == film.id }
            }
        } catch {
            print("Failed to delete film: \(error)")
        }
    }
    
    func updateFilm(_ film: Film, with data: EditedFilmData) async {
        let query = CKQuery(
            recordType: "Film",
            predicate: NSPredicate(format: "title == %@ AND year == %@", film.title, film.year)
        )
        
        do {
            let records = try await database.records(matching: query)
            if let record = try records.matchResults.first?.1.get() {
                record["genres"] = data.genres
                record["recommendedBy"] = data.recommendedBy
                record["intendedAudience"] = data.intendedAudience.rawValue
                record["watched"] = data.watched
                record["watchDate"] = data.watchDate
                record["streamingService"] = data.streamingService
                
                let updatedRecord = try await database.save(record)
                print("Successfully updated record with ID: \(updatedRecord.recordID)")
                
                // Update local array
                if let index = films.firstIndex(where: { $0.id == film.id }) {
                    films[index] = Film(
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
                        streamingService: data.streamingService
                    )
                }
            }
        } catch {
            print("Failed to update film: \(error)")
        }
    }
    
    // Add a logging function
    private func log(_ message: String, error: Error? = nil) {
        let logMessage = """
            [Filmz] \(message)
            Device: \(UIDevice.current.model)
            iOS: \(UIDevice.current.systemVersion)
            Error: \(error?.localizedDescription ?? "none")
            """
        print(logMessage)
        
        // Also save to CloudKit for remote debugging
        let record = CKRecord(recordType: "AppLog")
        record["message"] = logMessage
        record["timestamp"] = Date()
        record["device"] = UIDevice.current.model
        
        Task {
            try? await database.save(record)
        }
    }
    
    // Add logging to key operations
    func fetchFilms() async {
        do {
            // Create a query to fetch all films
            let query = CKQuery(recordType: "Film", predicate: .init(value: true))
            let descriptor = NSSortDescriptor(key: "title", ascending: true)
            query.sortDescriptors = [descriptor]
            
            let (matchResults, _) = try await database.records(matching: query)
            let films = matchResults.compactMap { result -> Film? in
                do {
                    let record = try result.1.get()
                    return Film.from(record: record)
                } catch {
                    log("Failed to process record", error: error)
                    return nil
                }
            }
            
            await MainActor.run {
                self.films = films
            }
            log("Successfully fetched \(films.count) films")
        } catch {
            log("Failed to fetch films", error: error)
        }
    }
    
    private func checkICloudStatus() {
        CKContainer.default().accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.iCloudStatus = "iCloud Available"
                case .noAccount:
                    self?.iCloudStatus = "No iCloud Account"
                case .restricted:
                    self?.iCloudStatus = "iCloud Restricted"
                case .couldNotDetermine:
                    self?.iCloudStatus = "Could not determine iCloud status: \(error?.localizedDescription ?? "")"
                @unknown default:
                    self?.iCloudStatus = "Unknown iCloud status"
                }
                self?.log("iCloud Status: \(self?.iCloudStatus ?? "")")
            }
        }
    }
}

// Helper extension to convert between CKRecord and Film
extension Film {
    static func from(record: CKRecord) -> Film? {
        // Only require the absolute minimum fields
        guard 
            let title = record["title"] as? String,
            let year = record["year"] as? String
        else { 
            print("Failed to load film: missing required fields (title or year)")
            return nil 
        }
        
        // All other fields are optional with defaults
        return Film(
            id: UUID(),  // Generate new ID if needed
            title: title,
            year: year,
            genres: record["genres"] as? [String] ?? [],
            imdbRating: 0.0,
            posterUrl: record["posterUrl"] as? String ?? "",
            description: record["description"] as? String ?? "",
            country: record["country"] as? String ?? "",
            language: record["language"] as? String ?? "",
            releaseDate: record["releaseDate"] as? Date ?? Date(),
            runtime: record["runtime"] as? Int ?? 0,
            plot: record["plot"] as? String ?? "",
            recommendedBy: record["recommendedBy"] as? String,
            intendedAudience: AudienceType(rawValue: record["intendedAudience"] as? String ?? "") ?? .alone,
            watched: record["watched"] as? Bool ?? false,
            watchDate: record["watchDate"] as? Date,
            streamingService: record["streamingService"] as? String
        )
    }
} 
