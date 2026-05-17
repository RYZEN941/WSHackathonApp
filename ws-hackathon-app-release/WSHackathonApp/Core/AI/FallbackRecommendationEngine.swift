//
//  FallbackRecommendationEngine.swift
//  WSHackathonApp
//
//  Rule-based recommendation engine for devices without Foundation Models support.
//

import Foundation

enum FallbackRecommendationEngine {
    
    // MARK: - Smart Cart Fallback
    
    /// Finds complementary products based on shared patterns, collections, and product types.
    static func cartRecommendations(
        cartItems: [CartItem],
        allProducts: [ProductItem]
    ) -> CartRecommendation {
        let cartIds = Set(cartItems.map { $0.id })
        let availableProducts = allProducts.filter { !cartIds.contains($0.id) }
        
        guard !cartItems.isEmpty, !availableProducts.isEmpty else {
            return CartRecommendation(
                detectedIntent: "Your Collection",
                reason: "Check out these items that go great with your cart.",
                products: []
            )
        }
        
        // Gather metadata from cart items
        var cartPatterns = Set<String>()
        var cartProductTypes = Set<String>()
        var cartCollections = Set<String>()
        var cartBrands = Set<String>()
        
        // Match cart item IDs to full product data
        for cartItem in cartItems {
            if let product = allProducts.first(where: { $0.id == cartItem.id }) {
                if let p = product.pattern { cartPatterns.insert(p) }
                if let pt = product.productType { cartProductTypes.insert(pt) }
                if let c = product.collection { cartCollections.insert(c) }
                if let b = product.brand { cartBrands.insert(b) }
            }
        }
        
        // Score available products by relevance
        var scoredProducts: [(product: ProductItem, score: Int)] = []
        
        for product in availableProducts {
            var score = 0
            
            // Same pattern (e.g., cookware, tabletop) = high relevance
            if let p = product.pattern, cartPatterns.contains(p) { score += 3 }
            
            // Same collection = very high relevance
            if let c = product.collection, cartCollections.contains(c) { score += 4 }
            
            // Same brand = moderate relevance
            if let b = product.brand, cartBrands.contains(b) { score += 2 }
            
            // Different product type but same pattern = complementary
            if let pt = product.productType, !cartProductTypes.contains(pt) {
                if let p = product.pattern, cartPatterns.contains(p) { score += 2 }
            }
            
            if score > 0 {
                scoredProducts.append((product, score))
            }
        }
        
        // Sort by score descending, take top 4
        let recommended = scoredProducts
            .sorted { $0.score > $1.score }
            .prefix(4)
            .map { $0.product }
        
        // Detect intent from patterns
        let intent = detectIntent(patterns: cartPatterns, types: cartProductTypes)
        
        return CartRecommendation(
            detectedIntent: intent,
            reason: "These items complement your \(intent.lowercased()) perfectly.",
            products: Array(recommended)
        )
    }
    
    // MARK: - Smart Registry Fallback
    
    /// Generates gift bundles based on budget and category preferences.
    static func registryRecommendations(
        occasion: RegistryEvent,
        budget: Double,
        categories: Set<String>,
        allProducts: [ProductItem]
    ) -> [GiftBundleDisplay] {
        // Filter products by selected categories
        let filtered = allProducts.filter { product in
            guard let pt = product.productType else { return false }
            if categories.isEmpty { return true }
            return categories.contains(where: { category in
                categoryMatchesProductType(category: category, productType: pt)
            })
        }
        
        guard !filtered.isEmpty else { return [] }
        
        // Sort by price to build budget-friendly bundles
        let sorted = filtered.sorted { ($0.price ?? 0) < ($1.price ?? 0) }
        
        // Generate up to 3 bundles
        var bundles: [GiftBundleDisplay] = []
        var usedIds = Set<String>()
        
        let themes = bundleThemes(for: occasion)
        
        for (index, theme) in themes.prefix(3).enumerated() {
            var bundleProducts: [ProductItem] = []
            var bundleTotal = 0.0
            
            // Pick products that fit in budget
            let startIndex = index % sorted.count
            let candidates = Array(sorted[startIndex...]) + Array(sorted[..<startIndex])
            
            for product in candidates {
                guard !usedIds.contains(product.id) else { continue }
                let price = product.price ?? 0
                if bundleTotal + price <= budget && bundleProducts.count < 4 {
                    bundleProducts.append(product)
                    bundleTotal += price
                    usedIds.insert(product.id)
                }
            }
            
            if !bundleProducts.isEmpty {
                bundles.append(GiftBundleDisplay(
                    themeName: theme.name,
                    themeDescription: theme.description,
                    products: bundleProducts
                ))
            }
        }
        
        return bundles
    }
    
    // MARK: - Recipe Fallback
    
    static func recipeRecommendations(
        recipe: Recipe,
        allProducts: [ProductItem]
    ) -> RecipeRecommendation {
        let title = recipe.title.lowercased()
        var recommendedTypes: [String] = []
        var message = "Check out these essentials that might help you prepare this recipe!"
        
        if title.contains("coq au vin") || title.contains("braise") {
            recommendedTypes.append("dutch-ovens")
            message = "Looks like you might need a Dutch Oven for this classic braise!"
        } else if title.contains("steak") || title.contains("sear") {
            recommendedTypes.append("fry-pans-skillets")
            message = "A high-quality skillet is essential for the perfect sear."
        } else if title.contains("salad") || title.contains("chop") {
            recommendedTypes.append("cutting-boards-storage")
            message = "Make prep easier with a solid cutting board."
        }
        
        // If no specific match, default to a general tool
        if recommendedTypes.isEmpty {
            recommendedTypes.append("cutting-boards-storage")
        }
        
        let matchedProducts = allProducts.filter { product in
            guard let pt = product.productType else { return false }
            return recommendedTypes.contains(pt)
        }.prefix(2)
        
        return RecipeRecommendation(
            detectedMessage: message,
            products: Array(matchedProducts)
        )
    }
    
    // MARK: - Helpers
    
    private static func detectIntent(patterns: Set<String>, types: Set<String>) -> String {
        if types.contains("pizza-stone") || types.contains("pizza-cutter") { return "Pizza Night" }
        if patterns.contains("bakeware") || types.contains("baking-sheet") { return "Baking & Pastry Making" }
        if patterns.contains("electrics") || types.contains("coffee-maker") { return "Sunday Brunch" }
        if patterns.contains("tabletop") || patterns.contains("glassware") { return "Hosting a Dinner Party" }
        if patterns.contains("food") { return "Cooking a Gourmet Meal" }
        if patterns.contains("cookware") || types.contains("dutch-ovens") { return "Making a Braise or Stew" }
        if patterns.contains("cutlery") { return "Prep Work for a Big Meal" }
        return "Cooking Project"
    }
    
    private static func categoryMatchesProductType(category: String, productType: String) -> Bool {
        let mapping: [String: [String]] = [
            "Kitchen": ["cutting-boards-storage", "cutting-board-oil", "lazy-susan"],
            "Cookware": ["dutch-ovens", "fry-pans-skillets"],
            "Coffee & Tea": ["coffee-maker", "cups-and-saucers", "tea-cups"],
            "Dining": ["tabletop-serveware-bowl", "cups-and-saucers"],
            "Bar & Glassware": ["bar-glasses-martini"],
            "Food & Pantry": ["oil"],
            "Home & Décor": ["lazy-susan", "tabletop-serveware-bowl"],
            "Bakeware": []
        ]
        
        guard let types = mapping[category] else { return false }
        return types.contains(productType)
    }
    
    private static func bundleThemes(for occasion: RegistryEvent) -> [(name: String, description: String)] {
        switch occasion {
        case .wedding:
            return [
                ("Kitchen Essentials", "Everything they need to start cooking together."),
                ("Entertaining Set", "Perfect for hosting their first dinner party."),
                ("Gourmet Starter", "Premium ingredients and tools for food lovers.")
            ]
        case .housewarming:
            return [
                ("New Home Basics", "Essential items every home needs."),
                ("Hosting & Entertaining", "Help them welcome guests in style."),
                ("Kitchen Upgrade", "Elevate their kitchen with premium tools.")
            ]
        case .birthday:
            return [
                ("Treat Yourself", "Indulgent items for a special celebration."),
                ("Cooking Enthusiast", "Perfect gifts for the home chef."),
                ("Coffee & Morning Ritual", "Start every day right.")
            ]
        case .anniversary:
            return [
                ("Romantic Dinner Set", "Create memorable dining experiences."),
                ("Premium Kitchen", "Upgrade their favorite cooking tools."),
                ("Cocktail Hour", "Everything for the perfect evening together.")
            ]
        case .babyShower:
            return [
                ("Family Kitchen", "Essentials for the growing family."),
                ("Meal Prep Made Easy", "Tools to simplify cooking for new parents."),
                ("Comfort & Home", "Warm, welcoming home essentials.")
            ]
        case .festiveGifting:
            return [
                ("Holiday Entertaining", "Host the perfect celebration."),
                ("Gourmet Gift Set", "Premium food and cooking essentials."),
                ("Festive Home", "Deck the halls with beautiful home items.")
            ]
        }
    }
}
