import SwiftUI

struct GenreButton:  View {
    let genre: String
    let action: () -> Void
    let isActive: Bool
    
    var body: some View {
        Button(action: action)
        {Text(genre)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isActive ? Color.accentColor : Color.gray.opacity(0.2))
            .foregroundColor(isActive ? .white : .primary)
            .cornerRadius(16)

        }
    }
} 

#Preview {
    VStack{
        GenreButton(genre: "All Genres", action : {}, isActive: true)
        GenreButton(genre: "Sci-Fi", action : {}, isActive: false)
    }
}
