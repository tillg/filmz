//
//  MyFilmDetailViewModel.swift
//  Filmz
//
//  Created by Till Gartner on 16.03.25.
//

import SwiftUI
import Logging 

enum FilmEditMode {
    case create
    case edit
}
@MainActor
class MyFilmDetailViewModel: ObservableObject {
    private(set) var myFilmId: UUID?
    private let myFilmStore: MyFilmStore
    private(set) var mode: FilmEditMode
    @Published var myFilm: MyFilm

    /// Use this initializer when editing an existing film in the store
    init(myFilmId: UUID, filmStore: MyFilmStore) {
        self.myFilmStore = filmStore
        if let existingFilm = filmStore.getFilmById(myFilmId) {
            self.myFilm = existingFilm
            self.mode = .edit
            self.myFilmId = myFilmId
        } else {
            // Film not found; fallback or throw an error if appropriate
            self.myFilm = MyFilm()
            self.mode = .create
        }
    }

    /// Use this initializer when creating a new film that doesn't yet exist in the store
    init(newFilm: MyFilm, filmStore: MyFilmStore) {
        self.myFilmStore = filmStore
        self.myFilm = newFilm
        self.mode = .create
        self.myFilmId = newFilm.id
    }

    // Commit changes based on the mode
    func commitChanges() async {
        switch mode {
        case .create:
            await myFilmStore.addMyFilm(myFilm)
        case .edit:
            let editedData = EditedFilmData(
                recommendedBy: myFilm.recommendedBy ?? "",
                intendedAudience: myFilm.intendedAudience,
                watched: myFilm.watched,
                watchDate: myFilm.watchDate,
                streamingService: myFilm.streamingService
            )
            await myFilmStore.updateMyFilm(myFilm, with: editedData)
        }
    }
}
