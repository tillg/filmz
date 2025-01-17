import SwiftUI

struct AddFilmView: View {
    let imdbResult: IMDBService.SearchResult
    
    @State private var selectedGenres: Set<String> = []
    @State private var watchStatus = false
    @State private var watchDate: Date?
    @State private var streamingService = ""
    @State private var recommendedBy = ""
    @State private var audience = Film.AudienceType.alone
    
    let availableGenres = ["Action", "Adventure", "Comedy", "Drama", "Horror", "Sci-Fi", "Thriller"]
    
    var body: some View {
        Form {
            Section("Movie Details") {
                AsyncImage(url: URL(string: imdbResult.Poster)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(systemName: "film")
                        .foregroundStyle(.gray)
                }
                .frame(maxHeight: 200)
                
                Text(imdbResult.Title)
                    .font(.headline)
                Text("Year: \(imdbResult.Year)")
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
                Button("Save") {
                    // TODO: Implement save functionality
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Add Film")
    }
} 