import SwiftUI

struct EditFilmView: View {
    let film: Film
    let filmStore: FilmStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedGenres: Set<String>
    @State private var watchStatus: Bool
    @State private var watchDate: Date?
    @State private var streamingService = ""
    @State private var recommendedBy: String
    @State private var audience: Film.AudienceType
    
    init(film: Film, filmStore: FilmStore) {
        self.film = film
        self.filmStore = filmStore
        _selectedGenres = State(initialValue: Set(film.genres))
        _watchStatus = State(initialValue: false) // TODO: Add watched status to Film model
        _recommendedBy = State(initialValue: film.recommendedBy ?? "")
        _audience = State(initialValue: film.intendedAudience)
    }
    
    let availableGenres = ["Action", "Adventure", "Comedy", "Drama", "Horror", "Sci-Fi", "Thriller"]
    
    var body: some View {
        Form {
            Section("Movie Details") {
                AsyncImage(url: URL(string: film.posterUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(systemName: "film")
                        .foregroundStyle(.gray)
                }
                .frame(maxHeight: 200)
                
                Text(film.title)
                    .font(.headline)
                Text("Year: \(film.year)")
            }
            
            Section("Genres") {
                ForEach(availableGenres, id: \.self) { genre in
                    Toggle(genre, isOn: Binding(
                        get: { selectedGenres.contains(genre) },
                        set: { isSelected in
                            if isSelected {
                                selectedGenres.insert(genre)
                            } else {
                                selectedGenres.remove(genre)
                            }
                        }
                    ))
                }
            }
            
            Section("Watch Status") {
                Toggle("Watched", isOn: $watchStatus)
                
                if watchStatus {
                    DatePicker("Watch Date", selection: .init(
                        get: { watchDate ?? Date() },
                        set: { watchDate = $0 }
                    ), displayedComponents: .date)
                    
                    TextField("Streaming Service", text: $streamingService)
                }
            }
            
            Section("Additional Info") {
                TextField("Recommended By", text: $recommendedBy)
                
                Picker("Intended Audience", selection: $audience) {
                    Text("Me alone").tag(Film.AudienceType.alone)
                    Text("Me and partner").tag(Film.AudienceType.partner)
                    Text("Family").tag(Film.AudienceType.family)
                }
            }
            
            Section {
                Button("Save Changes") {
                    Task {
                        // TODO: Implement update in FilmStore
                        await filmStore.updateFilm(film, with: EditedFilmData(
                            genres: Array(selectedGenres),
                            recommendedBy: recommendedBy,
                            intendedAudience: audience
                        ))
                        dismiss()
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Edit Film")
    }
}

struct EditedFilmData {
    let genres: [String]
    let recommendedBy: String
    let intendedAudience: Film.AudienceType
    // TODO: Add more editable fields
} 