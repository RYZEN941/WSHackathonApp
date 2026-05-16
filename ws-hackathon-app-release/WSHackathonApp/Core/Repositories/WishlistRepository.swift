//
//  WishlistRepository.swift
//  WSHackathonApp
//

import Combine
import Foundation

@MainActor
final class WishlistRepository: ObservableObject {

    @Published private(set) var items: [ProductItem] = []

    var count: Int { items.count }

    func contains(productId: String) -> Bool {
        items.contains { $0.id == productId }
    }

    func toggle(_ product: ProductItem) {
        if contains(productId: product.id) {
            remove(productId: product.id)
        } else {
            items.append(product)
        }
    }

    func remove(productId: String) {
        items.removeAll { $0.id == productId }
    }
}
