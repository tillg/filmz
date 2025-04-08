//
//  IMDbRatingView.swift
//  Filmz
//
//  Created by Till Gartner on 27.02.25.
//


import SwiftUI

struct ImdbRatingView: View {
    let rating: Double
    
    var body: some View {
        HStack(spacing: 4) {
            if rating > 0 {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text(String(format: "%.1f", rating))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
