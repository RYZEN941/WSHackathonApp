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


// MARK: - Recipe AI Response

@available(iOS 26, *)
@Generable
struct RecipeAIResponse {
    @Guide(description: "A short, friendly message explaining what equipment was found missing for this recipe")
    var detectedMessage: String
    
    @Guide(description: "List of general tool names needed for the recipe that the user might not have, e.g., 'Dutch Oven', 'Chef\\'s Knife'")
    var requiredTools: [String]
    
    @Guide(description: "List of specific product IDs from the catalog that match the required tools")
    var recommendedProductIds: [String]
}

// MARK: - Cart Generated Recipe AI Response

@available(iOS 26, *)
@Generable
struct CartRecipeAIResponse {
    @Guide(description: "A creative title for the recipe based on the cart ingredients/tools, e.g. 'Homemade Neapolitan Pizza'")
    var title: String
    
    @Guide(description: "A short, appetizing description of the recipe")
    var description: String
    
    @Guide(description: "List of required ingredients (including standard pantry staples)")
    var ingredients: [String]
    
    @Guide(description: "Step-by-step cooking instructions")
    var instructions: [String]
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

struct RecipeRecommendation: Identifiable {
    let id = UUID()
    let detectedMessage: String
    let products: [ProductItem]
}

struct CartGeneratedRecipe: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let ingredients: [String]
    let instructions: [String]
}

// MARK: - Similar Products AI Response

@available(iOS 26, *)
@Generable
struct SimilarProductsAIResponse {
    @Guide(description: "List of product IDs from the catalog that are highly similar or complementary to the selected product")
    var recommendedProductIds: [String]
}
