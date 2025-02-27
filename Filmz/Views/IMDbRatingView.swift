//
//  IMDbRatingView.swift
//  Filmz
//
//  Created by Till Gartner on 27.02.25.
//


import SwiftUI

struct IMDbRatingView: View {
    let rating: Double
    
    var body: some View {
        HStack(spacing: 4) {
            if rating > 0 {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .imageScale(.small)
                Text(String(format: "%.1f", rating))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}