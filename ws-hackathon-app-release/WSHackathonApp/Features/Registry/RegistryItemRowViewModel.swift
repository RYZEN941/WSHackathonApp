//
//  RegistryItemRowViewModel.swift
//  WSHackathonApp
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class RegistryItemRowViewModel: ObservableObject {

    let itemId: String

    @Published private(set) var title: String = ""
    @Published private(set) var priceText: String = ""
    @Published private(set) var quantity: Int = 0
    @Published private(set) var imageURL: URL?

    private let registryRepo: RegistryRepository
    private let cartRepo: CartRepository
    private let tabBarVM: WSTabBarViewModel
    private var cancellable: AnyCancellable?

    init(item: RegistryItem,
         registryRepo: RegistryRepository,
         cartRepo: CartRepository,
         tabbarVM: WSTabBarViewModel) {
        self.itemId = item.id
        self.registryRepo = registryRepo
        self.cartRepo = cartRepo
        self.tabBarVM = tabbarVM

        apply(item: item)

        cancellable = registryRepo.$currentRegistry
            .receive(on: DispatchQueue.main)
            .sink { [weak self] registry in
                guard let self else { return }
                if let updated = registry?.items.first(where: { $0.id == self.itemId }) {
                    self.apply(item: updated)
                } else {
                    self.quantity = 0
                }
            }
    }

    private func apply(item: RegistryItem) {
        title = item.title
        priceText = String(format: "$%.2f", item.price)
        quantity = item.quantity
        if let url = item.imageUrl {
            imageURL = URL(string: AppConstants.API.imageBasePath + url)
        } else {
            imageURL = nil
        }
    }

    func increaseQty() {
        withAnimation(WSAnimation.spring) {
            registryRepo.increaseQty(itemId)
        }
    }

    func decreaseQty() {
        withAnimation(WSAnimation.spring) {
            registryRepo.decreaseQty(itemId)
        }
    }

    func addToCart() {
        guard let item = registryRepo.currentRegistry?.items.first(where: { $0.id == itemId }) else {
            return
        }
        let product = ProductItem(
            id: item.id,
            title: item.title,
            price: item.price,
            path: item.imageUrl ?? "",
            availability: "ON_HAND",
            freeShip: nil,
            brand: nil,
            material: nil
        )
        cartRepo.add(product: product, quantity: item.quantity)
        tabBarVM.selectTab(.cart)
    }
}
