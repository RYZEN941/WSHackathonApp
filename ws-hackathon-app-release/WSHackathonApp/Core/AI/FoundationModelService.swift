//
//  FoundationModelService.swift
//  WSHackathonApp
//
//  Central AI service that wraps Apple's FoundationModels framework
//  for on-device AI recommendations.
//

import Foundation
import FoundationModels

@MainActor
final class FoundationModelService {
    
    static let shared = FoundationModelService()
    private init() {}
    
    // MARK: - Availability Check
    
    var isAvailable: Bool {
        if #available(iOS 26, *) {
            return SystemLanguageModel.default.availability == .available
        }
        return false
    }
    
    // MARK: - Smart Cart Recommendations
    
    func generateCartRecommendations(
        cartItems: [CartItem],
        allProducts: [ProductItem]
    ) async -> CartRecommendation {
        let cartIds = Set(cartItems.map { $0.id })
        let availableProducts = allProducts.filter { !cartIds.contains($0.id) }
        
        guard !cartItems.isEmpty, !availableProducts.isEmpty else {
            return CartRecommendation(
                detectedIntent: "Your Collection",
                reason: "Add more items to get personalized suggestions.",
                products: []
            )
        }
        
        // Try Foundation Models first
        if #available(iOS 26, *), isAvailable {
            do {
                let response = try await generateCartAI(cartItems: cartItems, allProducts: allProducts)
                let matchedProducts = response.recommendedProductIds.compactMap { id in
                    availableProducts.first(where: { $0.id == id })
                }
                
                if !matchedProducts.isEmpty {
                    return CartRecommendation(
                        detectedIntent: response.detectedIntent,
                        reason: response.reason,
                        products: matchedProducts
                    )
                }
            } catch {
                print("Foundation Model error (cart): \(error). Falling back to rules.")
            }
        }
        
        // Fallback to rule-based engine
        return FallbackRecommendationEngine.cartRecommendations(
            cartItems: cartItems,
            allProducts: allProducts
        )
    }
    
    // MARK: - Smart Registry Recommendations
    
    func generateRegistryRecommendations(
        occasion: RegistryEvent,
        budget: Double,
        categories: Set<String>,
        allProducts: [ProductItem]
    ) async -> [GiftBundleDisplay] {
        // Try Foundation Models first
        if #available(iOS 26, *), isAvailable {
            do {
                let response = try await generateRegistryAI(
                    occasion: occasion,
                    budget: budget,
                    categories: categories,
                    allProducts: allProducts
                )
                
                let bundles = response.bundles.compactMap { bundle -> GiftBundleDisplay? in
                    let products = bundle.productIds.compactMap { id in
                        allProducts.first(where: { $0.id == id })
                    }
                    guard !products.isEmpty else { return nil }
                    return GiftBundleDisplay(
                        themeName: bundle.themeName,
                        themeDescription: bundle.themeDescription,
                        products: products
                    )
                }
                
                if !bundles.isEmpty {
                    return bundles
                }
            } catch {
                print("Foundation Model error (registry): \(error). Falling back to rules.")
            }
        }
        
        // Fallback to rule-based engine
        return FallbackRecommendationEngine.registryRecommendations(
            occasion: occasion,
            budget: budget,
            categories: categories,
            allProducts: allProducts
        )
    }
    
    // MARK: - Private AI Methods
    
    @available(iOS 26, *)
    private func generateCartAI(
        cartItems: [CartItem],
        allProducts: [ProductItem]
    ) async throws -> CartAIResponse {
        let session = LanguageModelSession()
        
        // Build the product catalog context
        let catalogDescription = allProducts.map { product in
            var desc = "ID: \(product.id), Name: \(product.title), Price: $\(product.price ?? 0)"
            if let pt = product.productType { desc += ", Type: \(pt)" }
            if let p = product.pattern { desc += ", Pattern: \(p)" }
            if let c = product.collection { desc += ", Collection: \(c)" }
            if let b = product.brand { desc += ", Brand: \(b)" }
            if let m = product.material { desc += ", Material: \(m)" }
            return desc
        }.joined(separator: "\n")
        
        // Build cart items context
        let cartDescription = cartItems.map { item in
            "- \(item.title) (ID: \(item.id), $\(item.price), Qty: \(item.quantity))"
        }.joined(separator: "\n")
        
        let cartIds = Set(cartItems.map { $0.id })
        
        let prompt = """
        You are a smart shopping assistant for Williams Sonoma, a premium home and kitchen retailer.
        
        The customer has these items in their cart:
        \(cartDescription)
        
        Here is our complete product catalog:
        \(catalogDescription)
        
        Analyze what the customer is trying to build or collect based on their cart items. \
        Detect the shopping intent (e.g., "Cookware Collection", "Coffee Setup", "Entertaining Essentials", "Kitchen Prep Station"). \
        Then recommend complementary products from our catalog that would complete their set. \
        Only recommend products NOT already in the cart (exclude IDs: \(cartIds.joined(separator: ", "))). \
        Recommend 2-4 products maximum. \
        Make recommendations that genuinely complement the cart items — same collection, related use cases, or items typically bought together.
        """
        
        let response = try await session.respond(to: prompt, generating: CartAIResponse.self)
        return response.content
    }
    
    @available(iOS 26, *)
    private func generateRegistryAI(
        occasion: RegistryEvent,
        budget: Double,
        categories: Set<String>,
        allProducts: [ProductItem]
    ) async throws -> RegistryAIResponse {
        let session = LanguageModelSession()
        
        // Build catalog context
        let catalogDescription = allProducts.map { product in
            var desc = "ID: \(product.id), Name: \(product.title), Price: $\(product.price ?? 0)"
            if let pt = product.productType { desc += ", Type: \(pt)" }
            if let p = product.pattern { desc += ", Pattern: \(p)" }
            if let c = product.collection { desc += ", Collection: \(c)" }
            return desc
        }.joined(separator: "\n")
        
        let categoryList = categories.isEmpty ? "all categories" : categories.joined(separator: ", ")
        
        let prompt = """
        You are a gift registry assistant for Williams Sonoma, a premium home and kitchen retailer.
        
        A customer is creating a \(occasion.title) registry with a budget of $\(String(format: "%.2f", budget)).
        They are interested in these categories: \(categoryList).
        
        Here is our complete product catalog:
        \(catalogDescription)
        
        Create 2-3 curated gift bundles that:
        1. Each bundle has a creative theme name and brief description
        2. Each bundle's total price stays within the $\(String(format: "%.2f", budget)) budget
        3. Products are relevant to the \(occasion.title) occasion
        4. Products match the selected categories when possible
        5. Each bundle contains 2-4 products
        6. Bundles should feel like thoughtful, cohesive gift sets
        7. Try to use different products across bundles to give variety
        """
        
        let response = try await session.respond(to: prompt, generating: RegistryAIResponse.self)
        return response.content
    }
}
