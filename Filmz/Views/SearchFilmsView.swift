import SwiftUI

struct SearchFilmsView: View {
    let filmStore: FilmStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FilmzViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.isSearching && viewModel.searchResults.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if let error = viewModel.searchError {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                } else {
                    ForEach(viewModel.searchResults) { result in
                        NavigationLink {
                            AddFilmView(imdbResult: result, filmStore: filmStore, dismiss: dismiss)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            filmStore.log("SearchFilmsView appeared")
        }
        .onDisappear {
            filmStore.log("SearchFilmsView disappeared")
        }
    }
} 