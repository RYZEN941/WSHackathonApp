//
//  SmartPairingsViewModel.swift
//  WSHackathonApp
//

import Foundation
import Combine

struct RecommendedProduct: Identifiable {
    let id = UUID()
    let product: ProductItem
    let reason: String
}

@MainActor
class SmartPairingsViewModel: ObservableObject {
    @Published var recommendations: [RecommendedProduct] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // We keep track of what we've already recommended based on so we don't spam the API
    private var lastCartItemCount = 0
    
    func fetchRecommendationsIfNeeded(cartItems: [CartItem]) async {
        guard cartItems.count > 0, cartItems.count != lastCartItemCount else {
            return
        }
        
        lastCartItemCount = cartItems.count
        await fetchRecommendations(cartItems: cartItems)
    }
    
    func fetchRecommendations(cartItems: [CartItem]) async {
        guard !cartItems.isEmpty else {
            self.recommendations = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let currentItemNames = cartItems.map { $0.title }
            
            // Load catalog from local JSON for the hackathon mock
            guard let localDTOs: [ProductItemDTO] = LocalDataManager.load("skus.json") else {
                errorMessage = "Failed to load catalog"
                isLoading = false
                return
            }
            
            let recommendedIds = try await LLMService.shared.fetchSmartPairings(
                currentCartItems: currentItemNames,
                catalog: localDTOs
            )
            
            // Map the LLM's chosen IDs back to actual ProductItems
            var results: [RecommendedProduct] = []
            for recommendation in recommendedIds {
                if let dto = localDTOs.first(where: { $0.id == recommendation.productId }) {
                    let product = ProductItem(from: dto)
                    results.append(RecommendedProduct(product: product, reason: recommendation.reason))
                }
            }
            
            self.recommendations = results
            
        } catch {
            print("LLM Error: \(error.localizedDescription)")
            print("Detailed LLM Error: \(error)")
            errorMessage = "Failed to fetch AI recommendations."
        }
        
        isLoading = false
    }
}
