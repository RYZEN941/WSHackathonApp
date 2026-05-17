//
//  CartRecommendationView.swift
//  WSHackathonApp
//

import SwiftUI

struct CartRecommendationView: View {
    let recommendation: CartRecommendation
    let onAddProduct: (ProductItem) -> Void
    let onAddAll: () -> Void
    @State private var addedProductIds: Set<String> = []
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Header
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.wsSurface)
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.wsAccent)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("INSPIRED BY YOUR CART")
                            .font(WSFont.caption(9))
                            .foregroundStyle(Color.wsAccent)
                            .textCase(.uppercase)
                            .tracking(1.5)
                        
                        Text(recommendation.detectedIntent.uppercased())
                            .font(WSFont.heading(15))
                            .foregroundStyle(Color.wsNavy)
                            .tracking(0.5)
                        
                        Text(recommendation.reason)
                            .font(WSFont.body(11))
                            .foregroundStyle(Color.wsTextSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(Color.wsTextSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
            }
            .buttonStyle(.plain)
            
            // MARK: - Expanded Content
            if isExpanded {
            
            // MARK: - Product Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recommendation.products) { product in
                        recommendationCard(product: product)
                    }
                }
                .padding(16)
            }
            .background(Color.white)
            
            // MARK: - Footer / Add All
            if recommendation.products.count > 1 {
                Button(action: onAddAll) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .semibold))
                        Text(AppStrings.SmartCart.completeMySet)
                            .font(WSFont.subheading(13))
                        
                        Spacer()
                        
                        Text(completeSetPriceText)
                            .font(WSFont.price(14))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .wsPrimaryButtonBackground(cornerRadius: 8)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .background(Color.white)
            }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(WSGradient.cardStroke, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
    }
    
    private func recommendationCard(product: ProductItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            CustomAsyncImage(url: product.imageURL)
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.wsNavy.opacity(0.06), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(product.title)
                    .font(WSFont.body(11))
                    .foregroundStyle(Color.wsNavy)
                    .lineLimit(1)
                
                if let price = product.price {
                    Text(price, format: .currency(code: "USD"))
                        .font(WSFont.price(12))
                        .foregroundStyle(Color.wsAccent)
                }
            }
            
            Button(action: {
                withAnimation(WSAnimation.quickSpring) {
                    addedProductIds.insert(product.id)
                }
                onAddProduct(product)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: addedProductIds.contains(product.id) ? "checkmark" : "plus")
                        .font(.system(size: 10, weight: .bold))
                    Text(addedProductIds.contains(product.id) ? AppStrings.SmartCart.added : AppStrings.SmartCart.addToCart)
                        .font(WSFont.caption(10))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(addedProductIds.contains(product.id) ? Color.wsSuccess : Color.wsCharcoal)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(addedProductIds.contains(product.id))
        }
        .padding(10)
        .frame(width: 140)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.03), radius: 6, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.wsNavy.opacity(0.04), lineWidth: 1)
        )
    }
    
    private var completeSetPriceText: String {
        let total = recommendation.products
            .filter { !addedProductIds.contains($0.id) }
            .compactMap { $0.price }
            .reduce(0, +)
        return "+$\(String(format: "%.2f", total))"
    }
}
