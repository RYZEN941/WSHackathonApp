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
        
        Analyze what the customer is trying to cook, bake, or prepare based on their cart items. \
        Detect the culinary project or recipe intent (e.g., "Pizza Night", "Baking a Cake", "Making Homemade Pasta", "Sunday Brunch"). \
        Then recommend complementary products from our catalog that they would also need to make that specific recipe or project a success. \
        Only recommend products NOT already in the cart (exclude IDs: \(cartIds.joined(separator: ", "))). \
        Recommend 2-4 products maximum. \
        Make recommendations that are highly specific to the detected culinary project (e.g. if they added a pizza stone, recommend a pizza cutter or peel).
        """
        
        let response = try await session.respond(to: prompt, generating: CartAIResponse.self)
        return response.content
    }
    
    func generateCartRecipe(cartItems: [CartItem]) async -> CartGeneratedRecipe? {
        if #available(iOS 26, *), isAvailable {
            do {
                let response = try await generateCartRecipeAI(cartItems: cartItems)
                return CartGeneratedRecipe(
                    title: response.title,
                    description: response.description,
                    ingredients: response.ingredients,
                    instructions: response.instructions
                )
            } catch {
                print("Foundation Model error (cart recipe): \(error)")
                return nil
            }
        }
        return nil
    }
    
    @available(iOS 26, *)
    private func generateCartRecipeAI(cartItems: [CartItem]) async throws -> CartRecipeAIResponse {
        let session = LanguageModelSession()
        
        let cartDescription = cartItems.map { "- \($0.title)" }.joined(separator: "\n")
        
        let prompt = """
        You are a master chef for Williams Sonoma.
        
        The user has these items in their shopping cart:
        \(cartDescription)
        
        Analyze these tools and ingredients, and generate a beautiful, mouth-watering recipe that perfectly utilizes these specific items.
        If there are baking tools, give a baking recipe. If there are pizza tools, give a pizza recipe.
        
        Provide:
        1. A creative title
        2. A short appetizing description
        3. A list of ingredients (you can assume standard pantry staples, but definitely use any food items in the cart)
        4. Step-by-step instructions that explicitly mention using the tools from the cart.
        """
        
        let response = try await session.respond(to: prompt, generating: CartRecipeAIResponse.self)
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
    
    // MARK: - Recipe Recommendations
    
    func generateRecipeRecommendations(
        recipe: Recipe,
        allProducts: [ProductItem]
    ) async -> RecipeRecommendation {
        // Try Foundation Models first
        if #available(iOS 26, *), isAvailable {
            do {
                let response = try await generateRecipeAI(recipe: recipe, allProducts: allProducts)
                
                let matchedProducts = response.recommendedProductIds.compactMap { id in
                    allProducts.first(where: { $0.id == id })
                }
                
                if !matchedProducts.isEmpty {
                    return RecipeRecommendation(
                        detectedMessage: response.detectedMessage,
                        products: matchedProducts
                    )
                }
            } catch {
                print("Foundation Model error (recipe): \(error). Falling back to rules.")
            }
        }
        
        // Fallback to rule-based engine
        return FallbackRecommendationEngine.recipeRecommendations(
            recipe: recipe,
            allProducts: allProducts
        )
    }
    
    @available(iOS 26, *)
    private func generateRecipeAI(
        recipe: Recipe,
        allProducts: [ProductItem]
    ) async throws -> RecipeAIResponse {
        let session = LanguageModelSession()
        
        let catalogDescription = allProducts.map { product in
            var desc = "ID: \(product.id), Name: \(product.title), Price: $\(product.price ?? 0)"
            if let pt = product.productType { desc += ", Type: \(pt)" }
            if let b = product.brand { desc += ", Brand: \(b)" }
            return desc
        }.joined(separator: "\n")
        
        let prompt = """
        You are a culinary expert and shopping assistant for Williams Sonoma.
        
        A user is reading this recipe:
        Title: \(recipe.title)
        Ingredients:
        \(recipe.ingredients.joined(separator: "\n"))
        Instructions:
        \(recipe.instructions.joined(separator: "\n"))
        
        Here is our complete product catalog:
        \(catalogDescription)
        
        Analyze the recipe to determine what specific kitchen equipment (like Dutch Ovens, specific pans, knives, cutting boards) is required to cook it.
        Then, match those required tools with products from our catalog.
        
        Provide a friendly 'detectedMessage' (e.g., 'Looks like you might need a Dutch Oven for this classic braise!'), list the general 'requiredTools', and return the 'recommendedProductIds' of the matching items from our catalog. Limit to 1-3 highly relevant items.
        """
        
        let response = try await session.respond(to: prompt, generating: RecipeAIResponse.self)
        return response.content
    }
    
    // MARK: - Similar Products Recommendations
    
    func generateSimilarProductRecommendations(
        product: ProductItem,
        allProducts: [ProductItem]
    ) async -> [ProductItem] {
        // Try Foundation Models first
        if #available(iOS 26, *), isAvailable {
            do {
                let response = try await generateSimilarProductsAI(product: product, allProducts: allProducts)
                let matchedProducts = response.recommendedProductIds.compactMap { id in
                    allProducts.first(where: { $0.id == id && $0.id != product.id })
                }
                if !matchedProducts.isEmpty {
                    return matchedProducts
                }
            } catch {
                print("Foundation Model error (similar): \(error). Falling back to rules.")
            }
        }
        
        // Fallback rule-based logic
        return allProducts.filter { other in
            other.id != product.id && (
                other.productType == product.productType ||
                other.brand == product.brand ||
                (other.pattern != nil && other.pattern == product.pattern)
            )
        }.prefix(3).map { $0 }
    }
    
    @available(iOS 26, *)
    private func generateSimilarProductsAI(
        product: ProductItem,
        allProducts: [ProductItem]
    ) async throws -> SimilarProductsAIResponse {
        let session = LanguageModelSession()
        
        let catalogDescription = allProducts.map { other in
            var desc = "ID: \(other.id), Name: \(other.title), Price: $\(other.price ?? 0)"
            if let pt = other.productType { desc += ", Type: \(pt)" }
            if let p = other.pattern { desc += ", Pattern: \(p)" }
            if let c = other.collection { desc += ", Collection: \(c)" }
            if let b = other.brand { desc += ", Brand: \(b)" }
            return desc
        }.joined(separator: "\n")
        
        let prompt = """
        You are a smart retail recommendation assistant for Williams Sonoma.
        
        The customer is looking at this product:
        Name: \(product.title) (ID: \(product.id))
        Price: $\(product.price ?? 0)
        Type: \(product.productType ?? "None")
        Brand: \(product.brand ?? "None")
        Collection: \(product.collection ?? "None")
        Pattern: \(product.pattern ?? "None")
        
        Here is our complete product catalog:
        \(catalogDescription)
        
        Recommend 2-4 products from our catalog that are highly similar or complement the selected product (for example, if they look at a dutch oven, recommend other high-end cookware like pans or skillets; if they look at martini glasses, recommend decanters or other glassware). Do NOT recommend the selected product itself (exclude ID: \(product.id)).
        """
        
        let response = try await session.respond(to: prompt, generating: SimilarProductsAIResponse.self)
        return response.content
    }
}
