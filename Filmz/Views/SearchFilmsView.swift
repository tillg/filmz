import SwiftUI

struct SearchFilmsView: View {
    @StateObject private var viewModel = FilmzViewModel()
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    let filmStore: FilmStore
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField("Search for a movie or series (min. 3 characters)", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: searchText) { newValue in
                            viewModel.searchFilms(query: newValue)
                        }
                    
                    if searchText.count > 0 && searchText.count < 3 {
                        Text("Please enter at least 3 characters")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                
                if viewModel.isSearching {
                    Section {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                } else {
                    Section {
                        ForEach(viewModel.searchResults) { result in
                            NavigationLink {
                                AddFilmView(imdbResult: result, filmStore: filmStore, dismiss: dismiss)
                            } label: {
                                SearchResultRow(result: result)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Film")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
} 