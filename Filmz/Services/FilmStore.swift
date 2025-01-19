import CloudKit
import Foundation

@MainActor
class FilmStore: ObservableObject {
    @Published private(set) var films: [Film] = []
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
        print("Adding film: \(film.title)")
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
        
        do {
            let savedRecord = try await database.save(record)
            print("Successfully saved record with ID: \(savedRecord.recordID)")
            films.append(film)
        } catch {
            print("Failed to save film with error: \(error)")
        }
    }
    
    func deleteFilm(_ film: Film) async {
        // First find the record ID
        let query = CKQuery(
            recordType: "Film",
            predicate: NSPredicate(format: "title == %@ AND year == %d", film.title, film.year)
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
}

// Helper extension to convert between CKRecord and Film
extension Film {
    static func from(record: CKRecord) -> Film? {
        guard 
            let title = record["title"] as? String,
            let year = record["year"] as? Int,
            let genres = record["genres"] as? [String],
            let posterUrl = record["posterUrl"] as? String,
            let description = record["description"] as? String,
            let country = record["country"] as? String,
            let language = record["language"] as? String,
            let runtime = record["runtime"] as? Int,
            let plot = record["plot"] as? String,
            let audienceRaw = record["intendedAudience"] as? String,
            let audience = AudienceType(rawValue: audienceRaw)
        else { return nil }
        
        return Film(
            title: title,
            year: year,
            genres: genres,
            imdbRating: 0.0,
            posterUrl: posterUrl,
            description: description,
            country: country,
            language: language,
            releaseDate: Date(),
            runtime: runtime,
            plot: plot,
            recommendedBy: record["recommendedBy"] as? String ?? "",
            intendedAudience: audience
        )
    }
} 
