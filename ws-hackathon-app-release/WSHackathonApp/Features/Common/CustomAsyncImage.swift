//
//  CustomAsyncImage.swift
//  WSHackathonApp
//

import SwiftUI

struct CustomAsyncImage: View {
    let url: URL?
    @StateObject private var loader = CustomImageLoader()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.wsSurface

                if let image = loader.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .transition(.opacity.animation(.easeIn(duration: 0.25)))
                } else {
                    shimmerPlaceholder
                }
            }
        }
        .clipped()
        .onAppear { loader.load(url: url) }
        .onChange(of: url) { _, newURL in
            loader.load(url: newURL)
        }
    }

    private var shimmerPlaceholder: some View {
        Color.wsSurface
            .shimmer()
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 22, weight: .ultraLight))
                    .foregroundStyle(Color.wsMuted.opacity(0.6))
            }
    }
}
