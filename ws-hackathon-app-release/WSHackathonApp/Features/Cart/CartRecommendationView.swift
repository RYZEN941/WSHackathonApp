//
//  CartRecommendationView.swift
//  WSHackathonApp
//
//  AI-powered "Complete Your Set" recommendation section for the cart.
//

import SwiftUI

struct CartRecommendationView: View {
    
    let recommendation: CartRecommendation
    let onAddProduct: (ProductItem) -> Void
    let onAddAll: () -> Void
    @State private var addedProductIds: Set<String> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // MARK: - Header with gradient
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Text(AppStrings.SmartCart.aiPowered)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                        .textCase(.uppercase)
                        .tracking(1.2)
                }
                
                Text(recommendation.detectedIntent)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(recommendation.reason)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.15, green: 0.15, blue: 0.2), Color(red: 0.25, green: 0.2, blue: 0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // MARK: - Product Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recommendation.products) { product in
                        recommendationCard(product: product)
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGray6))
            
            // MARK: - Complete My Set Button
            if recommendation.products.count > 1 {
                Button(action: onAddAll) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.subheadline)
                        Text(AppStrings.SmartCart.completeMySet)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text(completeSetPriceText)
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(14)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.2, blue: 0.28), Color(red: 0.35, green: 0.28, blue: 0.45)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Recommendation Card
    
    private func recommendationCard(product: ProductItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Product image
            CustomAsyncImage(url: product.imageURL)
                .frame(width: 140, height: 140)
                .cornerRadius(12)
                .clipped()
            
            // Product title
            Text(product.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .foregroundColor(.primary)
                .frame(width: 140, alignment: .leading)
            
            // Price
            if let price = product.price {
                Text("$\(price, specifier: "%.2f")")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            // Add button
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    addedProductIds.insert(product.id)
                }
                onAddProduct(product)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: addedProductIds.contains(product.id) ? "checkmark" : "plus")
                        .font(.caption2)
                    Text(addedProductIds.contains(product.id) ? AppStrings.SmartCart.added : AppStrings.SmartCart.addToCart)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(addedProductIds.contains(product.id) ? .white : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    addedProductIds.contains(product.id)
                    ? Color.green
                    : Color.black
                )
                .cornerRadius(8)
            }
            .disabled(addedProductIds.contains(product.id))
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Helpers
    
    private var completeSetPriceText: String {
        let total = recommendation.products
            .filter { !addedProductIds.contains($0.id) }
            .compactMap { $0.price }
            .reduce(0, +)
        return "+$\(String(format: "%.2f", total))"
    }
}
