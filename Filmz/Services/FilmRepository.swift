import Foundation

protocol FilmRepository {
    func fetchAllFilms() async throws -> [Film]
    func addFilm(_ film: Film) async throws
    func updateFilm(_ film: Film, with data: EditedFilmData) async throws
    func deleteFilm(_ film: Film) async throws
}