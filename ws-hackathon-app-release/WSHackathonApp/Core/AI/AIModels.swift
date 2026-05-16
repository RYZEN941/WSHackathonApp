//
//  AIModels.swift
//  WSHackathonApp
//
//  Smart Cart & Smart Registry AI response models
//

import Foundation
import FoundationModels

// MARK: - Smart Cart AI Response

@available(iOS 26, *)
@Generable
struct CartAIResponse {
    @Guide(description: "A short label describing the detected shopping intent or set being built, e.g. 'Cookware Collection', 'Coffee Setup', 'Entertaining Essentials'")
    var detectedIntent: String
    
    @Guide(description: "A brief friendly sentence explaining why these products complement the cart items")
    var reason: String
    
    @Guide(description: "List of product IDs from the catalog that would complement the cart items to complete the set")
    var recommendedProductIds: [String]
}

// MARK: - Smart Registry AI Response

@available(iOS 26, *)
@Generable
struct RegistryAIResponse {
    @Guide(description: "Multiple curated gift bundle options, each with a theme")
    var bundles: [GiftBundle]
}

@available(iOS 26, *)
@Generable
struct GiftBundle {
    @Guide(description: "A creative theme name for this gift bundle, e.g. 'Coffee Lover\\'s Kit', 'Kitchen Essentials'")
    var themeName: String
    
    @Guide(description: "A short 1-2 sentence description of this bundle and who it is ideal for")
    var themeDescription: String
    
    @Guide(description: "List of product IDs from the catalog included in this bundle")
    var productIds: [String]
}

// MARK: - Display Models (non-Generable, for UI)

struct CartRecommendation: Identifiable {
    let id = UUID()
    let detectedIntent: String
    let reason: String
    let products: [ProductItem]
}

struct GiftBundleDisplay: Identifiable {
    let id = UUID()
    let themeName: String
    let themeDescription: String
    var products: [ProductItem]
    
    var totalPrice: Double {
        products.compactMap { $0.price }.reduce(0, +)
    }
}
