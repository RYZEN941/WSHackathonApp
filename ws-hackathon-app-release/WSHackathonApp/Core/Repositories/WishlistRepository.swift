//
//  WishlistRepository.swift
//  WSHackathonApp
//

import Combine
import Foundation

@MainActor
final class WishlistRepository: ObservableObject {

    @Published private(set) var items: [ProductItem] = []
    
    private var user1WishlistItems: [ProductItem] = []
    private var user2WishlistItems: [ProductItem] = []
    private var currentUserId: String = "user1"
    
    func switchUser(toUserId userId: String) {
        if currentUserId == "user1" {
            user1WishlistItems = items
        } else {
            user2WishlistItems = items
        }
        
        currentUserId = userId
        items = userId == "user1" ? user1WishlistItems : user2WishlistItems
    }

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
