import SwiftUI

struct CacheTestView: View {
    @State private var loadCount = 0
    
    let testFilm = Film(
        title: "Test Film",
        year: "2024",
        genres: [],
        imdbRating: 0.0,
        posterUrl: "https://m.media-amazon.com/images/M/MV5BMDFkYTc0MGEtZmNhMC00ZDIzLWFmNTEtODM1ZmRlYWMwMWFmXkEyXkFqcGdeQXVyMTMxODk2OTU@._V1_SX300.jpg",
        description: "",
        country: "",
        language: "",
        releaseDate: Date(),
        runtime: 0,
        plot: "",
        intendedAudience: .alone
    )
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                PosterImage(film: testFilm)
                    .frame(height: 200)
                
                Button("Clear Cache") {
                    ImageCache.shared.clearCache()
                    loadCount = 0
                }
                .buttonStyle(.bordered)
                
                Button("Reload Image") {
                    loadCount += 1
                }
                .buttonStyle(.bordered)
                
                Button("Show Cache Info") {
                    ImageCache.shared.debugCacheInfo()
                }
                .buttonStyle(.bordered)
                
                Text("Load count: \(loadCount)")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Cache Test")
        }
    }
}

#Preview {
    CacheTestView()
} 
