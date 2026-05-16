//
//  ShimmerView.swift
//  WSHackathonApp
//
//  Reusable shimmer/skeleton loading animation for AI loading states.
//

import SwiftUI

struct ShimmerView: View {
    @State private var phase: CGFloat = -1.0
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(.systemGray5), location: max(0, phase - 0.3)),
                .init(color: Color(.systemGray4), location: phase),
                .init(color: Color(.systemGray5), location: min(1, phase + 0.3))
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .onAppear {
            withAnimation(
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                phase = 2.0
            }
        }
    }
}

struct ShimmerCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder
            ShimmerView()
                .frame(width: 140, height: 140)
                .cornerRadius(12)
            
            // Title placeholder
            ShimmerView()
                .frame(width: 120, height: 14)
                .cornerRadius(4)
            
            // Price placeholder
            ShimmerView()
                .frame(width: 60, height: 14)
                .cornerRadius(4)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

struct ShimmerRecommendationSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header shimmer
            HStack(spacing: 8) {
                ShimmerView()
                    .frame(width: 24, height: 24)
                    .cornerRadius(12)
                ShimmerView()
                    .frame(width: 180, height: 18)
                    .cornerRadius(4)
            }
            .padding(.horizontal, 16)
            
            // Cards shimmer
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        ShimmerCardView()
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
    }
}
