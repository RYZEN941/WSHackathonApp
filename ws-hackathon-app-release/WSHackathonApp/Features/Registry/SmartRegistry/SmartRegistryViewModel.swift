//
//  SmartRegistryViewModel.swift
//  WSHackathonApp
//
//  ViewModel for AI-powered budget-based gift discovery wizard.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class SmartRegistryViewModel: ObservableObject {
    
    // MARK: - Inputs
    @Published var budget: Double = 200.0
    @Published var selectedCategories: Set<String> = []
    
    // MARK: - Outputs
    @Published private(set) var giftBundles: [GiftBundleDisplay] = []
    @Published private(set) var isGenerating = false
    @Published private(set) var hasGenerated = false
    
    // MARK: - Dependencies
    private let aiService = FoundationModelService.shared
    private let catalogService = ProductCatalogService.shared
    private var registryRepo: RegistryRepository?
    private var occasion: RegistryEvent = .wedding
    
    // MARK: - Available Categories
    let availableCategories: [String] = [
        "Kitchen",
        "Cookware",
        "Coffee & Tea",
        "Dining",
        "Bar & Glassware",
        "Food & Pantry",
        "Home & Décor",
        "Bakeware"
    ]
    
    // MARK: - Budget Presets
    let budgetPresets: [Double] = [50, 100, 200, 500, 1000]
    
    // MARK: - Bind
    
    func bind(registryRepo: RegistryRepository, occasion: RegistryEvent) {
        self.registryRepo = registryRepo
        self.occasion = occasion
        
        // Load catalog
        Task {
            await catalogService.loadIfNeeded()
        }
    }
    
    // MARK: - Category Toggle
    
    func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
    
    func isCategorySelected(_ category: String) -> Bool {
        selectedCategories.contains(category)
    }
    
    // MARK: - Generate Bundles
    
    func generateBundles() async {
        isGenerating = true
        hasGenerated = false
        giftBundles = []
        
        let bundles = await aiService.generateRegistryRecommendations(
            occasion: occasion,
            budget: budget,
            categories: selectedCategories,
            allProducts: catalogService.products
        )
        
        withAnimation(.spring(response: 0.5)) {
            self.giftBundles = bundles
            self.isGenerating = false
            self.hasGenerated = true
        }
    }
    
    // MARK: - Actions
    
    func addBundleToRegistry(_ bundle: GiftBundleDisplay) {
        guard let repo = registryRepo else { return }
        
        for product in bundle.products {
            repo.addProduct(product)
        }
        
        // Set budget on registry if not already set
        if repo.currentRegistry?.budget == nil {
            repo.setBudget(budget)
        }
    }
    
    func removeBundleItem(_ product: ProductItem, from bundle: GiftBundleDisplay) {
        guard let index = giftBundles.firstIndex(where: { $0.id == bundle.id }) else { return }
        giftBundles[index].products.removeAll(where: { $0.id == product.id })
        
        // Remove empty bundles
        if giftBundles[index].products.isEmpty {
            giftBundles.remove(at: index)
        }
    }
    
    // MARK: - Display Helpers
    
    var budgetText: String {
        "$\(String(format: "%.0f", budget))"
    }
    
    var occasionText: String {
        occasion.title
    }
}
