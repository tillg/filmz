import Foundation

protocol MyFilmRepository {
    func fetchAllMyFilms() async throws -> [MyFilm]
    func addMyFilm(_ myFilm: MyFilm) async throws
    func updateMyFilm(_ myFilm: MyFilm, with data: EditedFilmData) async throws
    func deleteMyFilm(_ myFilm: MyFilm) async throws
}


struct EditedFilmData {
    let recommendedBy: String
    let intendedAudience: MyFilm.AudienceType
    let watched: Bool
    let watchDate: Date?
    let streamingService: String?
}
