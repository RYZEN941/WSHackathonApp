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
    @Published private(set) var registriesRevision = 0

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

        registryRepository.$registries
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.registriesRevision += 1 }
            .store(in: &cancellables)
    }

    var cartQuantity: Int {
        _ = cartRevision
        return cartRepository?.items.first(where: { $0.id == product.id })?.quantity ?? 0
    }

    var registryQuantity: Int {
        _ = registriesRevision
        return registryRepository?.registries.reduce(0) { $0 + ($1.items.first(where: { $0.id == product.id })?.quantity ?? 0) } ?? 0
    }

    var inCart: Bool { cartQuantity > 0 }
    var inRegistry: Bool { registryQuantity > 0 }
    var canAddToRegistry: Bool { registryRepository?.isActiveRegistry == true }
    var registries: [Registry] { registryRepository?.registries ?? [] }

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

    func addToRegistry(_ registryId: UUID? = nil) {
        withAnimation(WSAnimation.spring) {
            registryRepository?.addProduct(product, to: registryId)
        }
    }

    func removeFromRegistry(_ registryId: UUID? = nil) {
        guard let repo = registryRepository else { return }
        withAnimation(WSAnimation.spring) {
            if let id = registryId {
                repo.removeItem(product.id, from: id)
            } else {
                // Remove from all if no specific id provided
                for registry in repo.registries {
                    repo.removeItem(product.id, from: registry.id)
                }
            }
        }
    }
}
