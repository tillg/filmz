// Filmz/Views/SearchResultRow.swift

import SwiftUI

struct SearchResultRow: View {
    let result: IMDBService.SearchResult
    
    var body: some View {
        HStack(spacing: 12) {
            PosterImage()
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
