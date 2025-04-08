// Filmz/Views/SearchResultRow.swift

import SwiftUI

struct SearchResultRow: View {
    let result: ImdbFilmService.ImdbSearchResult
    
    var body: some View {
        HStack(spacing: 12) {
            PosterImage(imageUrl: result.Poster)
            .frame(width: 50, height: 75)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.Title)
                    .font(.headline)
                Text(result.Year)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}


#Preview {
    let batmanSearchResult = ImdbFilmService.ImdbSearchResult(
        imdbID: "tt0372784",
        Title: "Batman Begins",
        Year: "2005",
        Poster: "https://m.media-amazon.com/images/M/MV5BODIyMDdhNTgtNDlmOC00MjUxLWE2NDItODA5MTdkNzY3ZTdhXkEyXkFqcGc@._V1_SX300.jpg"
    )
    let lassoSearchResult = ImdbFilmService.ImdbSearchResult(
        imdbID: "tt10986410",
        Title: "Ted Lasso",
        Year: "2022-",
        Poster: "https://m.media-amazon.com/images/M/MV5BZmI3YWVhM2UtNDZjMC00YTIzLWI2NGUtZWIxODZkZjVmYTg1XkEyXkFqcGc@._V1_SX300.jpg"
    )

    List {
        SearchResultRow(result: batmanSearchResult)
        SearchResultRow(result: lassoSearchResult)

    }
}
