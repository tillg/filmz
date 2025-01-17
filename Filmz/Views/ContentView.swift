import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FilmzViewModel()
    @State private var searchText = ""
    @State private var showingAddFilm = false
    
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
                                AddFilmView(imdbResult: result)
                            } label: {
                                SearchResultRow(result: result)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filmz")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddFilm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
}

#Preview {
    ContentView()
} 