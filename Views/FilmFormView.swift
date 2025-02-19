import SwiftUI

struct FilmFormView: View {
    @State private var imdbResult: IMDBService.SearchResult?

    var body: some View {
        if let result = imdbResult {
            let dummyFilm = Film.dummy(from: result)
            PosterImage(film: dummyFilm)
                .frame(maxHeight: 200)
        } else {
            // Placeholder for the original code
        }
    }
}

struct FilmFormView_Previews: PreviewProvider {
    static var previews: some View {
        FilmFormView()
    }
} 