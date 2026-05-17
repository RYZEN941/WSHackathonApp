//
//  ProductCatalogService.swift
//  WSHackathonApp
//
//  Shared singleton to load and cache the product catalog.
//  Used by both Smart Cart and Smart Registry features.
//

import Foundation
import Combine

@MainActor
final class ProductCatalogService: ObservableObject {
    
    static let shared = ProductCatalogService()
    
    @Published private(set) var products: [ProductItem] = []
    @Published private(set) var isLoaded = false
    
    private var hasLoaded = false
    
    private init() {}
    
    // MARK: - Load Products
    
    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        
        do {
            let dtos: [ProductItemDTO] = try await APIClient.shared.request(Endpoint.products())
            self.products = dtos.map { ProductItem(from: $0) }
        } catch {
            print("ProductCatalogService: Network failed: \(error)")
        }
        
        isLoaded = true
    }
    
    // MARK: - Lookup Methods
    
    func product(byId id: String) -> ProductItem? {
        products.first(where: { $0.id == id })
    }
    
    func products(byType productType: String) -> [ProductItem] {
        products.filter { $0.productType == productType }
    }
    
    func products(byPattern pattern: String) -> [ProductItem] {
        products.filter { $0.pattern == pattern }
    }
}
