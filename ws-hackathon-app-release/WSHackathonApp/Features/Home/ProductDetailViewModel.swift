//
//  ProductDetailViewModel.swift
//  WSHackathonApp
//

import Combine
import SwiftUI

@MainActor
final class ProductDetailViewModel: ObservableObject {

    let product: ProductItem

    @Published private(set) var cartRevision = 0
    @Published private(set) var registryRevision = 0

    private var cartRepository: CartRepository?
    private var registryRepository: RegistryRepository?
    private var cancellables = Set<AnyCancellable>()

    init(product: ProductItem) {
        self.product = product
    }

    func bind(cartRepository: CartRepository, registryRepository: RegistryRepository) {
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

    var cartQuantity: Int {
        _ = cartRevision
        return cartRepository?.items.first(where: { $0.id == product.id })?.quantity ?? 0
    }

    var registryQuantity: Int {
        _ = registryRevision
        return registryRepository?.currentRegistry?.items.first(where: { $0.id == product.id })?.quantity ?? 0
    }

    var inCart: Bool { cartQuantity > 0 }
    var inRegistry: Bool { registryQuantity > 0 }
    var canAddToRegistry: Bool { registryRepository?.isActiveRegistry == true }

    func addToCart() {
        withAnimation(WSAnimation.spring) {
            cartRepository?.add(product: product)
        }
    }

    func removeFromCart() {
        withAnimation(WSAnimation.spring) {
            cartRepository?.remove(productId: product.id)
        }
    }

    func addToRegistry() {
        withAnimation(WSAnimation.spring) {
            registryRepository?.addProduct(product)
        }
    }

    func removeFromRegistry() {
        withAnimation(WSAnimation.spring) {
            registryRepository?.removeItem(product.id)
        }
    }
}
