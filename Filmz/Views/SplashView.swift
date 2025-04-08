//
//  LoadingView.swift
//  Filmz
//
//  Created by Till Gartner on 20.03.25.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Initializing…")
                .padding(.top, 8)
        }
    }
}

#Preview {
    SplashView()
}
