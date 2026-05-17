//
//  HomeViewModel.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 04/04/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var products: [ProductItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedCategory: String?
    @Published private(set) var cartRevision = 0
    @Published private(set) var registryRevision = 0

    private var hasLoaded = false
    private var cartRepository: CartRepository?
    private var registryRepository: RegistryRepository?
    private var cancellables = Set<AnyCancellable>()

    func bind(cartRepository: CartRepository,
              registryRepository: RegistryRepository) {
        self.cartRepository = cartRepository
        self.registryRepository = registryRepository

        cancellables.removeAll()

        cartRepository.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.cartRevision += 1 }
            .store(in: &cancellables)

        registryRepository.$registries
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.registryRevision += 1 }
            .store(in: &cancellables)
    }

    // Cart
    func addToCart(_ product: ProductItem) {
        withAnimation(WSAnimation.spring) {
            cartRepository?.add(product: product)
        }
    }

    func removeFromCart(_ product: ProductItem) {
        withAnimation(WSAnimation.spring) {
            cartRepository?.remove(productId: product.id)
        }
    }

    // Registry
    func addToRegistry(_ product: ProductItem, to registryId: UUID? = nil) {
        withAnimation(WSAnimation.spring) {
            registryRepository?.addProduct(product, to: registryId)
        }
    }
    
    func canAddToRegistry(_ product: ProductItem) -> Bool {
        if let registryRepository, registryRepository.isActiveRegistry {
            return true
        }
        return false
    }
    
    func removeFromRegistry(_ product: ProductItem) {
        guard let repo = registryRepository else { return }
        withAnimation(WSAnimation.spring) {
            for registry in repo.registries {
                repo.removeItem(product.id, from: registry.id)
            }
        }
    }

    func quantity(for product: ProductItem) -> Int {
        _ = cartRevision
        return cartRepository?.items.first(where: { $0.id == product.id })?.quantity ?? 0
    }

    func registryQuantity(for product: ProductItem) -> Int {
        _ = registryRevision
        return registryRepository?.registries.reduce(0) { $0 + ($1.items.first(where: { $0.id == product.id })?.quantity ?? 0) } ?? 0
    }
    
    var filteredProducts: [ProductItem] {
        var result = products
        
        if let category = selectedCategory {
            result = result.filter { product in
                let pt = product.productType ?? ""
                let title = product.title.lowercased()
                return categoryMatches(category: category, productType: pt, title: title)
            }
        }
        
        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        return result
    }
    
    var categories: [String] {
        ["All", "Kitchen", "Cookware", "Coffee & Tea", "Dining", "Bar & Glassware", "Food & Pantry", "Home & Décor"]
    }
    
    private func categoryMatches(category: String, productType: String, title: String) -> Bool {
        if category == "All" { return true }
        
        let mapping: [String: [String]] = [
            "Kitchen": ["cutting-boards", "cutting-board", "lazy-susan", "kitchen", "oil", "prep", "board", "knife"],
            "Cookware": ["dutch-oven", "fry-pan", "skillet", "oven", "pan", "sauce-pan", "cook", "pot"],
            "Coffee & Tea": ["coffee", "tea", "mug", "espresso", "cup", "saucer", "brew"],
            "Dining": ["tabletop", "serveware", "bowl", "plate", "dinnerware", "server", "dish", "napkin"],
            "Bar & Glassware": ["bar", "glass", "wine", "martini", "cocktail", "flute", "tumbler", "decanter"],
            "Food & Pantry": ["oil", "syrup", "extract", "pantry", "food", "salt", "pepper", "spice", "balsamic"],
            "Home & Décor": ["lazy-susan", "candle", "decor", "vase", "towel", "linens", "pillow", "throw"]
        ]
        
        guard let validKeywords = mapping[category] else { return false }
        
        // Match by product type OR partial match in title
        return validKeywords.contains { keyword in
            productType.localizedCaseInsensitiveContains(keyword) || title.contains(keyword)
        }
    }
    
    func fetchProducts() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        
        isLoading = true
        errorMessage = nil
        
        do {
            let dtos: [ProductItemDTO] = try await APIClient.shared.request(Endpoint.products())
            self.products = dtos.map { ProductItem(from: $0) }
        } catch {
            print("API fetch failed: \(error)")
            self.errorMessage = "Failed to load products. Please check your connection."
            self.products = []
        }
        
        isLoading = false
    }
}
