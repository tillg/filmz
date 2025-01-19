import SwiftUI

struct MyMoviesView: View {
    var body: some View {
        NavigationView {
            List {
                Text("Your saved movies will appear here")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("My Movies")
        }
    }
}

struct MyMoviesView_Previews: PreviewProvider {
    static var previews: some View {
        MyMoviesView()
    }
} 