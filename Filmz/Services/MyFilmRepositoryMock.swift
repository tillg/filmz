//
//  MyFilmRepositoryMock.swift
//  Filmz
//
//  Created by Till Gartner on 01.04.25.
//

import Logging

class MyFilmRepositoryMock: MyFilmRepository {
    private var logger = Logger(label: "MyFilmRepositoryMock")
    var films: [MyFilm] = [
        MyFilm(imdbId: "tt0111161", recommendedBy: "Alice", intendedAudience: .alone),
        MyFilm(imdbId: "tt0068646", recommendedBy: "Bob", intendedAudience: .family)
    ]
    
    func fetchAllMyFilms() async throws -> [MyFilm] {
        logger.info("MyFilmRepositoryMock: fetchAllMyFilms return \(films.count) Films")
        return films
    }

    func addMyFilm(_ myFilm: MyFilm) async throws {
        films.append(myFilm)
    }
    
    func deleteMyFilm(_ myFilm: MyFilm) async throws {
        films.removeAll { $0.id == myFilm.id }
    }
    
    func updateMyFilm(_ myFilm: MyFilm, with data: EditedFilmData) async throws {
        guard let index = films.firstIndex(where: { $0.id == myFilm.id }) else { return }
        films[index] = MyFilm(
            id: myFilm.id,
            imdbId: myFilm.imdbId,
            recommendedBy: data.recommendedBy,
            intendedAudience: data.intendedAudience
        )
    }
}
