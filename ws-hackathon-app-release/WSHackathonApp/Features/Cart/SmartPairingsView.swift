//
//  SmartPairingsView.swift
//  WSHackathonApp
//

import SwiftUI

struct SmartPairingsView: View {
    @StateObject private var viewModel = SmartPairingsViewModel()
    let cartItems: [CartItem]
    let onAddToCart: (ProductItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            if viewModel.isLoading {
                Text("Smart Pairings")
                    .font(.headline)
                    .padding(.horizontal)
                
                HStack {
                    Spacer()
                    ProgressView("Consulting WS Chefs...")
                        .padding()
                    Spacer()
                }
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            } else if !viewModel.recommendations.isEmpty {
                Text("Smart Pairings")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.recommendations) { rec in
                            RecommendedProductCard(
                                recommendation: rec,
                                onAdd: { onAddToCart(rec.product) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onChange(of: cartItems.count) { newValue in
            Task {
                await viewModel.fetchRecommendationsIfNeeded(cartItems: cartItems)
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchRecommendationsIfNeeded(cartItems: cartItems)
            }
        }
    }
}

struct RecommendedProductCard: View {
    let recommendation: RecommendedProduct
    let onAdd: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let url = recommendation.product.imageURL {
                CustomAsyncImage(url: url)
                    .frame(width: 140, height: 140)
                    .cornerRadius(8)
            } else if let name = recommendation.product.localImageName {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140, height: 140)
                    .cornerRadius(8)
                    .clipped()
            } else {
                Color.gray.opacity(0.3)
                    .frame(width: 140, height: 140)
                    .cornerRadius(8)
            }
            
            Text(recommendation.product.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .frame(height: 40, alignment: .top)
            
            Text("AI Pick: " + recommendation.reason)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .frame(height: 45, alignment: .top)
            
            Button(action: onAdd) {
                Text("Add")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
        }
        .frame(width: 140)
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
