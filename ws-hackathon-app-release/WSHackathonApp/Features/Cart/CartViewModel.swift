//
//  CartViewModel.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 05/04/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class CartViewModel: ObservableObject {

    @Published private(set) var items: [CartItem] = []
    @Published private(set) var recommendation: CartRecommendation?
    @Published private(set) var isLoadingRecommendations = false
    
    @Published private(set) var generatedRecipe: CartGeneratedRecipe?
    @Published private(set) var isGeneratingRecipe = false
    
    private var cancellable: AnyCancellable?
    private var recommendationCancellable: AnyCancellable?
    private var repository: CartRepository?
    private let aiService = FoundationModelService.shared
    private let catalogService = ProductCatalogService.shared
    
    private var recommendationTask: Task<Void, Never>?
    
    func bind(repository: CartRepository) {
        guard self.repository == nil else { return }
        self.repository = repository
        self.items = repository.items
        
        cancellable = repository.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedItems in
                self?.items = updatedItems
                self?.debouncedFetchRecommendations()
            }
        
        // Load catalog for AI recommendations
        Task {
            await catalogService.loadIfNeeded()
            // Fetch recommendations if cart already has items
            if !repository.items.isEmpty {
                await fetchRecommendations()
            }
        }
    }
    
    var isEmptyCart: Bool {
        items.isEmpty
    }
    
    var totalPriceText: String {
        String(format: "$%.2f", repository?.totalPrice ?? 0)
    }
    
    var totalPrice: Double {
        repository?.totalPrice ?? 0
    }
    
    var showRecommendations: Bool {
        items.count >= 1 && (isLoadingRecommendations || recommendation != nil)
    }
    
    func removeItem(_ item: CartItem) {
        repository?.remove(productId: item.id)
    }
    
    func removeCompletely(_ item: CartItem) {
        repository?.removeCompletely(productId: item.id)
    }
    
    func add(_ item: CartItem) {
        repository?.increaseQuantity(productId: item.id)
    }
    
    // MARK: - AI Recommendations
    
    func addRecommendation(_ product: ProductItem) {
        repository?.add(product: product)
    }
    
    func addAllRecommendations() {
        guard let recommendation = recommendation else { return }
        for product in recommendation.products {
            repository?.add(product: product)
        }
        // Clear recommendations after adding all
        self.recommendation = nil
    }
    
    func clearCart() {
        repository?.clear()
    }
    
    // MARK: - Private
    
    private var debounceWorkItem: DispatchWorkItem?
    
    private func debouncedFetchRecommendations() {
        debounceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                await self?.fetchRecommendations()
            }
        }
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: workItem)
    }
    
    private func fetchRecommendations() async {
        // Cancel any existing recommendation task
        recommendationTask?.cancel()
        
        guard !items.isEmpty else {
            recommendation = nil
            generatedRecipe = nil
            return
        }
        
        isLoadingRecommendations = true
        isGeneratingRecipe = true
        
        recommendationTask = Task {
            async let recommendationsResult = aiService.generateCartRecommendations(
                cartItems: items,
                allProducts: catalogService.products
            )
            
            async let recipeResult = aiService.generateCartRecipe(
                cartItems: items
            )
            
            let result = await recommendationsResult
            let generated = await recipeResult
            
            guard !Task.isCancelled else { return }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                if !result.products.isEmpty {
                    self.recommendation = result
                } else {
                    self.recommendation = nil
                }
                
                self.generatedRecipe = generated
            }
            
            self.isLoadingRecommendations = false
            self.isGeneratingRecipe = false
        }
    }
}

