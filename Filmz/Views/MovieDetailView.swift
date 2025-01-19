import SwiftUI

struct MovieDetailView: View {
    let result: IMDBService.SearchResult
    @State private var watchStatus = false
    @State private var watchDate: Date = Date()
    @State private var streamingService = ""
    @State private var recommendedBy = ""
    
    var body: some View {
        List {
            // Movie Poster and Basic Info
            Section {
                AsyncImage(url: URL(string: result.Poster)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(maxHeight: 300)
                
                Text(result.Title)
                    .font(.headline)
                Text("Year: \(result.Year)")
                    .foregroundStyle(.secondary)
            }
            
            // Watch Status
            Section("Watch Status") {
                Toggle("Watched", isOn: $watchStatus)
                
                if watchStatus {
                    DatePicker("Watch Date", selection: $watchDate, displayedComponents: .date)
                    TextField("Streaming Service", text: $streamingService)
                }
            }
            
            // Additional Info
            Section("Additional Information") {
                TextField("Recommended By", text: $recommendedBy)
            }
            
            // Save Button
            Section {
                Button(action: {
                    // TODO: Implement save functionality
                }) {
                    Text("Save to My Movies")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.blue)
                }
            }
        }
        .navigationTitle("Movie Details")
    }
}

#Preview {
    NavigationView {
        MovieDetailView(result: IMDBService.SearchResult(
            imdbID: "tt0111161",
            Title: "The Shawshank Redemption",
            Year: "1994",
            Poster: "https://m.media-amazon.com/images/M/MV5BMDFkYTc0MGEtZmNhMC00ZDIzLWFmNTEtODM1ZmRlYWMwMWFmXkEyXkFqcGdeQXVyMTMxODk2OTU@._V1_SX300.jpg"
        ))
    }
} 