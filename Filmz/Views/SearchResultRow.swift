import SwiftUI

struct SearchResultRow: View {
    let result: IMDBService.SearchResult
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: result.Poster)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "film")
                    .foregroundStyle(.gray)
            }
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