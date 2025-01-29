import CloudKit
import OSLog
import Foundation

actor CloudKitFilmRepository: FilmRepository {
    private let database: CKDatabase
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "CloudKitFilmRepository")
    
    init(containerIdentifier: String = "iCloud.com.grtnr.Filmz") {
        let container = CKContainer(identifier: containerIdentifier)
        self.database = container.privateCloudDatabase
        logger.info("CloudKitFilmRepository initialized")
    }
    
    func fetchAllFilms() async throws -> [Film] {
        logger.info("Fetching all films from CloudKit")
        
        let query = CKQuery(recordType: "Film", predicate: .init(value: true))
        let descriptor = NSSortDescriptor(key: "title", ascending: true)
        query.sortDescriptors = [descriptor]
        
        do {
            let (matchResults, _) = try await database.records(matching: query)
            let loadedFilms = matchResults.compactMap { result -> Film? in
                do {
                    let record = try result.1.get()
                    return from(record: record)
                } catch {
                    logger.error("Error decoding CKRecord: \\(error.localizedDescription)")
                    return nil
                }
            }
            return loadedFilms
        } catch {
            logger.error("fetchAllFilms failed: \\(error.localizedDescription)")
            throw error
        }
    }
    
    func addFilm(_ film: Film) async throws {
        logger.info("Adding film to CloudKit: \\(film.title)")
        
        let record = CKRecord(recordType: "Film")
        toRecord(record, from: film)
        
        do {
            _ = try await database.save(record)
            logger.info("Successfully saved film record: \\(film.title)")
        } catch {
            logger.error("Error saving film record: \\(error.localizedDescription)")
            throw error
        }
    }
    
    func updateFilm(_ film: Film, with data: EditedFilmData) async throws {
        logger.info("Updating film in CloudKit: \\(film.title)")
        
        let query = CKQuery(
            recordType: "Film",
            predicate: NSPredicate(format: "title == %@ AND year == %@", film.title, film.year)
        )
        
        do {
            let records = try await database.records(matching: query)
            guard let record = try records.matchResults.first?.1.get() else {
                logger.error("No matching record found to update for \\(film.title)")
                return
            }
            
            // Update record with edited data
            if !data.genres.isEmpty {
                record["genres"] = data.genres
            }
            record["recommendedBy"] = data.recommendedBy
            record["intendedAudience"] = data.intendedAudience.rawValue
            record["watched"] = data.watched
            record["watchDate"] = data.watchDate
            record["streamingService"] = data.streamingService
            
            do {
                _ = try await database.save(record)
                logger.info("Successfully updated film record: \\(film.title)")
            } catch {
                logger.error("Error updating film record: \\(error.localizedDescription)")
                throw error
            }
        } catch {
            logger.error("updateFilm failed for \\(film.title): \\(error.localizedDescription)")
            throw error
        }
    }
    
    func deleteFilm(_ film: Film) async throws {
        logger.info("Deleting film from CloudKit: \\(film.title)")
        
        let query = CKQuery(
            recordType: "Film",
            predicate: NSPredicate(format: "title == %@ AND year == %@", film.title, film.year)
        )
        
        do {
            let records = try await database.records(matching: query)
            if let record = try records.matchResults.first?.1.get() {
                try await database.deleteRecord(withID: record.recordID)
                logger.info("Successfully deleted record for film: \\(film.title)")
            } else {
                logger.warning("No matching record found to delete for \\(film.title)")
            }
        } catch {
            logger.error("deleteFilm failed for \\(film.title): \\(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - CKRecord Mapping Helpers
    
    private func from(record: CKRecord) -> Film? {
        guard
            let title = record["title"] as? String,
            let year = record["year"] as? String
        else {
            logger.error("Failed to load film: missing required fields (title or year)")
            return nil
        }
        
        return Film(
            id: UUID(),
            title: title,
            year: year,
            genres: record["genres"] as? [String] ?? [],
            imdbRating: 0.0, // We don't store IMDB rating in CloudKit
            posterUrl: record["posterUrl"] as? String ?? "",
            posterAsset: record["posterAsset"] as? CKAsset,
            description: record["description"] as? String ?? "",
            country: record["country"] as? String ?? "",
            language: record["language"] as? String ?? "",
            releaseDate: record["releaseDate"] as? Date ?? Date(),
            runtime: record["runtime"] as? Int ?? 0,
            plot: record["plot"] as? String ?? "",
            recommendedBy: record["recommendedBy"] as? String,
            intendedAudience: Film.AudienceType(rawValue: record["intendedAudience"] as? String ?? "") ?? .alone,
            watched: record["watched"] as? Bool ?? false,
            watchDate: record["watchDate"] as? Date,
            streamingService: record["streamingService"] as? String,
            dateAdded: record["dateAdded"] as? Date ?? Date()
        )
    }
    
    private func toRecord(_ record: CKRecord, from film: Film) {
        record["title"] = film.title
        record["year"] = film.year
        record["genres"] = film.genres
        record["posterUrl"] = film.posterUrl
        record["posterAsset"] = film.posterAsset
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
        record["dateAdded"] = film.dateAdded
    }
}