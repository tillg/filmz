import CloudKit
import Logging
import Foundation

/// CloudKitFilmRepository is responsible for persisting film data to iCloud
/// using CloudKit. It implements the FilmRepository protocol and handles all
/// CloudKit-specific operations including:
/// - Storing films in the user's private database
/// - Managing CloudKit records and assets
/// - Handling CloudKit-specific errors
/// - Converting between Film models and CKRecord objects
actor MyFilmRepositoryCK: MyFilmRepository {

    /// The CloudKit database used for storage (private database)
    private let database: CKDatabase
    private let recordType: String = "Film"
    
    /// Logger instance for debugging and error tracking
    private let logger = Logger(label: "MyFilmRepositoryCK")
    
    /// Initializes the repository with a CloudKit container identifier
    /// - Parameter containerIdentifier: The CloudKit container identifier. Defaults to "iCloud.com.grtnr.Filmz"
    init(containerIdentifier: String = "iCloud.com.grtnr.Filmz") {
        let container = CKContainer(identifier: containerIdentifier)
        self.database = container.privateCloudDatabase
        logger.info("MyFilmRepositoryCK initialized")
    }
    
    /// Fetches all films from CloudKit
    /// - Returns: An array of Film objects
    /// - Throws: CloudKit errors if the fetch fails
    /// - Note: Results are sorted by title in ascending order
    func fetchAllMyFilms() async throws -> [MyFilm] {
        logger.info("Fetching all myFilms from CloudKit")
        
        let query = CKQuery(recordType: recordType, predicate: .init(value: true))
        let descriptor = NSSortDescriptor(key: "title", ascending: true)
        query.sortDescriptors = [descriptor]
        
        do {
            let (matchResults, _) = try await database.records(matching: query)
            let loadedFilms = matchResults.compactMap { result -> MyFilm? in
                do {
                    let record = try result.1.get()
                    return from(record: record)
                } catch {
                    logger.error("Error decoding CKRecord: \(error.localizedDescription)")
                    return nil
                }
            }
            return loadedFilms
        } catch {
            logger.error("fetchAllFilms failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Adds a new film to CloudKit
    /// - Parameter film: The film to add
    /// - Throws: CloudKit errors if the save fails
    /// - Note: This creates a new CKRecord with the film's data and any associated assets
    func addMyFilm(_ film: MyFilm) async throws {
        logger.info("Adding film to CloudKit with IMDB Id: \(film.imdbId)")
        
        let record = CKRecord(recordType: recordType)
        toRecord(record, from: film)
        
        do {
            _ = try await database.save(record)
            logger.info("Successfully saved film record with IMDB Id: \(film.imdbId)")
        } catch {
            logger.error("Error saving film record: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Updates an existing film in CloudKit
    /// - Parameters:
    ///   - film: The film to update
    ///   - data: The new data to apply
    /// - Throws: CloudKit errors if the update fails
    /// - Note: This method:
    ///   1. Finds the existing record by title and year
    ///   2. Updates only the fields that can be edited
    ///   3. Preserves other fields
    func updateMyFilm(_ film: MyFilm, with data: EditedFilmData) async throws {
        logger.info("Updating film in CloudKit with IMDB Id: \(film.imdbId)")
        
        let query = CKQuery(
            recordType: recordType,
            predicate: NSPredicate(format: "imdbId == %@", film.imdbId ?? "")
        )
        
        do {
            let records = try await database.records(matching: query)
            guard let record = try records.matchResults.first?.1.get() else {
                logger.error("No matching record found to update for with IMDB Id \(film.imdbId)")
                return
            }
            
            // Update record with edited data
            record["recommendedBy"] = data.recommendedBy
            record["intendedAudience"] = data.intendedAudience.rawValue
            record["watched"] = data.watched
            record["watchDate"] = data.watchDate
            record["streamingService"] = data.streamingService
            
            do {
                _ = try await database.save(record)
                logger.info("Successfully updated film record with IMDB Id: \(film.imdbId)")
            } catch {
                logger.error("Error updating film record: \(error.localizedDescription)")
                throw error
            }
        } catch {
            logger.error("updateFilm failed with IMDB Id \(film.imdbId): \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Deletes a film from CloudKit
    /// - Parameter film: The film to delete
    /// - Throws: CloudKit errors if the deletion fails
    /// - Note: This method finds the record by title and year before deleting
    func deleteMyFilm(_ film: MyFilm) async throws {
        logger.info("Deleting film from CloudKit with IMDB Id: \(film.imdbId)")
        
        let query = CKQuery(
            recordType: recordType,
            predicate: NSPredicate(format: "imdbId == %@@", film.imdbId ?? "")
        )
        
        do {
            let records = try await database.records(matching: query)
            if let record = try records.matchResults.first?.1.get() {
                try await database.deleteRecord(withID: record.recordID)
                logger.info("Successfully deleted record for film with IMDB Id: \(film.imdbId)")
            } else {
                logger.warning("No matching record found to delete for film with IMDB Id\(film.imdbId)")
            }
        } catch {
            logger.error("deleteFilm failed for fil with IMDB Id\(film.imdbId): \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - CKRecord Mapping Helpers
    
    /// Converts a CKRecord to a Film model
    /// - Parameter record: The CloudKit record to convert
    /// - Returns: A MyFilm object if conversion succeeds, nil otherwise
    private func from(record: CKRecord) -> MyFilm? {

        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString) else {
            logger.error("CKrecord has no valid id")
            return nil
        }
        guard let imdbIdString = record["imdbId"] as? String else {
            logger.error("CKrecord has no valid imdbId")
            return nil
        }
        return MyFilm(
            id: id,
            imdbId: imdbIdString,
            recommendedBy: record["recommendedBy"] as? String,
            intendedAudience: MyFilm.AudienceType(rawValue: record["intendedAudience"] as? String ?? "") ?? .alone,
            watched: record["watched"] as? Bool ?? false,
            watchDate: record["watchDate"] as? Date,
            streamingService: record["streamingService"] as? String,
            dateAdded: record["dateAdded"] as? Date ?? Date()
        )
    }
    
    /// Updates a CKRecord with data from a Film model
    /// - Parameters:
    ///   - record: The CloudKit record to update
    ///   - myFilm: The film data to use
    private func toRecord(_ record: CKRecord, from myFilm: MyFilm) {
        record["id"] = myFilm.id.uuidString
        record["imdbId"] = myFilm.imdbId
        record["recommendedBy"] = myFilm.recommendedBy ?? ""
        record["intendedAudience"] = myFilm.intendedAudience.rawValue
        record["watched"] = myFilm.watched
        record["watchDate"] = myFilm.watchDate
        record["streamingService"] = myFilm.streamingService
        record["dateAdded"] = myFilm.dateAdded
    }
}
