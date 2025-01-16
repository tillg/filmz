//
//  ContentView.swift
//  Filmz
//
//  Created by Till Gartner on 16.01.25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "movieclapper")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("FILMZ")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
