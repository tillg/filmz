import SwiftUI
import Logging

struct SearchFilmsView: View {
    let filmStore: MyFilmStore
    private let logger = Logger(label: "SearchFilmsView")

    @StateObject private var viewModel = FilmzSearchModel()
    @State private var searchText = ""
    
    @MainActor
    var body: some View {
            List {
                if let error = viewModel.serviceInitError {
                    Text("Failed to initialize IMDB service: \(error.localizedDescription)")
                        .foregroundColor(.red)
                } else if viewModel.isSearching && viewModel.searchResults.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if let error = viewModel.searchError {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                } else {
                    ForEach(viewModel.searchResults) { result in
                        NavigationLink {
                            MyFilmDetailView(viewModel: makeDetailViewModel(for: result, filmStore: filmStore))
                        } label: {
                            SearchResultRow(result: result)
                        }
                    }
                    
                    if viewModel.canLoadMore {
                        Button {
                            Task {
                                await viewModel.loadMore()
                            }
                        } label: {
                            HStack {
                                Text("Load More")
                                if viewModel.isSearching {
                                    ProgressView()
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            } 
            .navigationTitle("Add Film")
            .searchable(text: $searchText)
            .onChange(of: searchText) { oldValue, newValue in
                viewModel.search(newValue)
            }
        
        .onAppear {
            logger.info("SearchFilmsView appeared")
        }
        .onDisappear {
            logger.info("SearchFilmsView disappeared")
        }
    }
}

@MainActor private func makeDetailViewModel(for result: ImdbFilmService.ImdbSearchResult, filmStore: MyFilmStore) -> MyFilmDetailViewModel {
    let myFilm = MyFilm(imdbId: result.imdbID, intendedAudience: .family)
    return MyFilmDetailViewModel(newFilm: myFilm, filmStore: filmStore)
}

#Preview {
    let myFilmStore = MyFilmStore()
    NavigationView {
        SearchFilmsView(filmStore: myFilmStore)
    }
}
