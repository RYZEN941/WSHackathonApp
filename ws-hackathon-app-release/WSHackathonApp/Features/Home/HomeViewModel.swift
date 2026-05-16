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

        registryRepository.$currentRegistry
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
    func addToRegistry(_ product: ProductItem) {
        withAnimation(WSAnimation.spring) {
            registryRepository?.addProduct(product)
        }
    }
    
    func canAddToRegistry(_ product: ProductItem) -> Bool {
        if let registryRepository, registryRepository.isActiveRegistry {
            return true
        }
        return false
    }
    
    func removeFromRegistry(_ product: ProductItem) {
        withAnimation(WSAnimation.spring) {
            registryRepository?.removeItem(product.id)
        }
    }

    func quantity(for product: ProductItem) -> Int {
        _ = cartRevision
        return cartRepository?.items.first(where: { $0.id == product.id })?.quantity ?? 0
    }

    func registryQuantity(for product: ProductItem) -> Int {
        _ = registryRevision
        return registryRepository?.currentRegistry?.items.first(where: { $0.id == product.id })?.quantity ?? 0
    }
    
    var filteredProducts: [ProductItem] {
        if searchText.isEmpty {
            return products
        } else {
            return products.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
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
            print(error)
            errorMessage = "Failed to load products"
        }
        
        isLoading = false
    }
}
