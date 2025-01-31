import Testing
import CloudKit
@testable import Filmz

struct FilmTests {
    // MARK: - Test Data
    
    func createTestFilm() -> Film {
        return Film(
            id: UUID(),
            title: "Test Movie",
            year: "2024",
            genres: ["Action", "Drama"],
            imdbRating: 7.5,
            posterUrl: "https://example.com/poster.jpg",
            posterAsset: nil,
            description: "A test movie description",
            trailerUrl: "https://example.com/trailer",
            country: "USA",
            language: "English",
            releaseDate: Date(),
            runtime: 120,
            plot: "A detailed plot summary",
            recommendedBy: "John Doe",
            intendedAudience: .family,
            watched: false,
            watchDate: nil,
            streamingService: "Netflix"
        )
    }
    
    // MARK: - Initialization Tests
    
    @Test
    func testFilmInitialization() throws {
        let film = createTestFilm()
        
        #expect(film.title == "Test Movie")
        #expect(film.year == "2024")
        #expect(film.genres.count == 2)
        #expect(film.myRating == nil)
        #expect(film.imdbRating == 7.5)
        #expect(film.runtime == 120)
        #expect(!film.watched)
        #expect(film.watchDate == nil)
        #expect(film.intendedAudience == .family)
    }
    
    // MARK: - Rating Validation Tests
    
    @Test
    func testValidMyRating() {
        var film = createTestFilm()
        
        // Test valid ratings
        film.myRating = 1
        #expect(film.myRating == 1)
        
        film.myRating = 10
        #expect(film.myRating == 10)
        
        // Test nil rating
        film.myRating = nil
        #expect(film.myRating == nil)
    }
    
    @Test
    func testValidImdbRating() {
        var film = createTestFilm()
        
        film.imdbRating = 0
        #expect(film.imdbRating == 0)
        
        film.imdbRating = 10
        #expect(film.imdbRating == 10)
        
        film.imdbRating = 7.8
        #expect(film.imdbRating == 7.8)
    }
    
    // MARK: - Runtime Validation Tests
    
    @Test
    func testValidRuntime() {
        var film = createTestFilm()
        
        film.runtime = 1
        #expect(film.runtime == 1)
        
        film.runtime = 240
        #expect(film.runtime == 240)
    }
    
    // MARK: - Codable Tests
    
    @Test
    func testEncodingAndDecoding() throws {
        let originalFilm = createTestFilm()
        
        // Encode to Data
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalFilm)
        
        // Decode back to Film
        let decoder = JSONDecoder()
        let decodedFilm = try decoder.decode(Film.self, from: data)
        
        // Verify properties match
        #expect(decodedFilm.id == originalFilm.id)
        #expect(decodedFilm.title == originalFilm.title)
        #expect(decodedFilm.year == originalFilm.year)
        #expect(decodedFilm.genres == originalFilm.genres)
        #expect(decodedFilm.myRating == originalFilm.myRating)
        #expect(decodedFilm.imdbRating == originalFilm.imdbRating)
        #expect(decodedFilm.runtime == originalFilm.runtime)
        #expect(decodedFilm.watched == originalFilm.watched)
        #expect(decodedFilm.intendedAudience == originalFilm.intendedAudience)
    }
    
    // MARK: - CloudKit Asset Tests
    
    @Test
    func testPosterAssetHandling() throws {
        // Create a temporary file for testing
        let tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_poster.jpg")
        try Data().write(to: tempFileURL)
        
        var film = createTestFilm()
        film.posterAsset = CKAsset(fileURL: tempFileURL)
        
        #expect(film.posterAsset != nil)
        #expect(film.posterAsset?.fileURL?.path == tempFileURL.path)
        
        // Clean up
        try? FileManager.default.removeItem(at: tempFileURL)
    }
    
    // MARK: - Edge Cases
    
    @Test
    func testEmptyStrings() {
        let film = Film(
            id: UUID(),
            title: "",
            year: "",
            genres: [],
            imdbRating: 0,
            posterUrl: "",
            posterAsset: nil,
            description: "",
            trailerUrl: nil,
            country: "",
            language: "",
            releaseDate: Date(),
            runtime: 1,
            plot: "",
            recommendedBy: nil,
            intendedAudience: .alone,
            watched: false,
            watchDate: nil,
            streamingService: nil
        )
        
        #expect(film.title.isEmpty)
        #expect(film.year.isEmpty)
        #expect(film.genres.isEmpty)
        #expect(film.description.isEmpty)
        #expect(film.plot.isEmpty)
    }
}
