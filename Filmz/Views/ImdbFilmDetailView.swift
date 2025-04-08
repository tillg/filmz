import Logging
import SwiftUI

struct ImdbFilmDetailView: View {
    let imdbId: String
    @State private var imdbFilm: ImdbFilm?
    @State private var isLoading = true
    @State private var error: Error?

    private var formattedRating: String {
        String(format: "%.1f", imdbFilm?.imdbRating ?? 0)
    }

    private let logger = Logger(label: "ImdbFilmDetailVie")

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let error = error {
                Text(
                    "Failed to load film details: \(error.localizedDescription)"
                )
                .foregroundStyle(.red)
            } else {
                PosterImage(imageUrl: imdbFilm?.posterUrl)
                    .clipped()
                Text(
                    "\(imdbFilm?.title ?? "Unknown Title") - \(imdbFilm?.year ?? "Unknown Year")"
                )
                .font(.title)
                GenrePillsHList(genres: imdbFilm?.genres ?? [])
                ImdbRatingView(rating: imdbFilm?.imdbRating ?? 0)

                if imdbFilm?.runtime != "" {
                    Text("Runtime: \(imdbFilm?.runtime ?? "")")
                        .foregroundStyle(.secondary)
                }

                // Plot
                if let details = imdbFilm, details.plot != "N/A" {
                    Text(details.plot)
                        .font(.body)
                }
            }
        }
        .task {
            logger.info("Loading film details....")
            //await loadImdbFilmDetails()
        }
        .onAppear {
            logger.info("ImdbFilmDetailView view appeared")
            Task {
                logger.info("ImdbFilmDetailView About to call loadImdbFilmDetails...")
                await loadImdbFilmDetails()
                }
        }
    }
        

    private func loadImdbFilmDetails() async {
        logger.info("loadImdbFilmDetails: Loading film details....")
        isLoading = true
        do {
            let imdbService = try ImdbFilmService()
            imdbFilm = try await imdbService.fetchFilmDetails(imdbId: imdbId)
        } catch {
            logger.error("Failed to load details: \(error)")
            //print("Failed to load details: \(error)")
            self.error = error
        }
        isLoading = false
    }
}

#Preview {
    let batmanId = "tt0372784"
    let lassoId = "tt10986410"
    NavigationView {
        ImdbFilmDetailView(imdbId: lassoId)
    }
}
