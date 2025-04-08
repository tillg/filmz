import CloudKit
import Foundation
import Logging

/// CloudKitImdbFilmRepository is responsible for persisting IMDB film data to iCloud
/// using CloudKit. It handles all
/// CloudKit-specific operations including:
/// - Storing IMDB films in the public database
/// - Handling CloudKit-specific errors
/// - Converting between ImdbFilm models and CKRecord objects
actor ImdbFilmRepositoryCK {
    /// The CloudKit database used for storage (private database)
    private let database: CKDatabase
    private let logger = Logger(label: "com.grtnr.Filmz.CloudKitImdbFilmRepository")

    /// Initializes the repository with a CloudKit container identifier
    /// - Parameter containerIdentifier: The CloudKit container identifier. Defaults to "iCloud.com.grtnr.Filmz"
    init(containerIdentifier: String = "iCloud.com.grtnr.ImdbFilmz") {
        let container = CKContainer(identifier: containerIdentifier)
        self.database = container.publicCloudDatabase
        logger.info("CloudKitImdbFilmRepository initialized")
    }

    /// Adds a new film to CloudKit
    /// - Parameter imdbFilm: The film to add
    /// - Throws: CloudKit errors if the save fails
    /// - Note: This creates a new CKRecord with the IMDB film's data
    func addFilm(_ imdbFilm: ImdbFilm) async throws {
        logger.info("Adding IMDB film to CloudKit: \(imdbFilm.title)")

        let record = CKRecord(recordType: "ImdbFilm")
        toRecord(record, from: imdbFilm)

        do {
            _ = try await database.save(record)
            logger.info("Successfully saved film record: \(imdbFilm.title)")
        } catch {
            logger.error(
                "Error saving film record: \(error.localizedDescription)")
            throw error
        }
    }

    /// Deletes a film from CloudKit
    /// - Parameter film: The film to delete
    /// - Throws: CloudKit errors if the deletion fails
    /// - Note: This method finds the record by title and year before deleting
    func deleteFilm(_ imdbFilmId: String) async throws {
        logger.info(
            "Deleting film from CloudKit with IMDB Film Id: \(imdbFilmId)")

        let query = CKQuery(
            recordType: "ImdbFilm",
            predicate: NSPredicate(format: "imdbId == %@", imdbFilmId)
        )

        do {
            let records = try await database.records(matching: query)
            if let record = try records.matchResults.first?.1.get() {
                try await database.deleteRecord(withID: record.recordID)
                logger.info(
                    "Successfully deleted record for film with IMDB Id: \(imdbFilmId)"
                )
            } else {
                logger.warning(
                    "No matching record found to delete for IMDB Id \(imdbFilmId)"
                )
            }
        } catch {
            logger.error(
                "deleteFilm failed for film with IMDB Film Id \(imdbFilmId): \(error.localizedDescription)"
            )
            throw error
        }
    }

    // MARK: - CKRecord Mapping Helpers

    /// Converts a CKRecord to a IMDB Film model
    /// - Parameter record: The CloudKit record to convert
    /// - Returns: A ImdbFilm object if conversion succeeds, nil otherwise
    private func from(record: CKRecord) -> ImdbFilm? {
        guard
            let title = record["title"] as? String,
            let year = record["year"] as? String
        else {
            logger.error(
                "Failed to load IMDB film: missing required fields (title or year)"
            )
            return nil
        }

        return ImdbFilm(
            imdbId: record["imdbId"] as? String ?? "",
            title: title,
            year: year,
            genres: record["genres"] as? [String] ?? [],
            imdbRating: 0.0,  // We don't store IMDB rating in CloudKit
            posterUrl: record["posterUrl"] as? String ?? "",
            description: record["description"] as? String ?? "",
            country: record["country"] as? String ?? "",
            language: record["language"] as? String ?? "",
            releaseDate: record["releaseDate"] as? Date ?? Date(),
            runtime: record["runtime"] as? String ?? "",
            plot: record["plot"] as? String ?? ""
        )
    }

    /// Updates a CKRecord with data from a ImdbFilm model
    /// - Parameters:
    ///   - record: The CloudKit record to update
    ///   - imdbFilm: TheIMDB  film data to use
    private func toRecord(_ record: CKRecord, from imdbFilm: ImdbFilm) {
        record["title"] = imdbFilm.title
        record["year"] = imdbFilm.year
        record["genres"] = imdbFilm.genres
        record["posterUrl"] = imdbFilm.posterUrl
        record["country"] = imdbFilm.country
        record["language"] = imdbFilm.language
        record["runtime"] = imdbFilm.runtime
        record["plot"] = imdbFilm.plot
    }
}
