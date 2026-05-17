//
//  RegistryRepository.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import Combine
import Foundation

@MainActor
final class RegistryRepository: ObservableObject {
    
    @Published var registries: [Registry] = []
    @Published var selectedRegistryId: UUID?
    @Published var notifications: [CoupleNotification] = []
    @Published var pendingGuestViewCode: String? = nil
    /// itemId → (funded, total) for group gifts
    @Published var groupGiftData: [String: (funded: Double, total: Double)] = [
        // Demo seeds – partially funded group gifts visible immediately
        "2453926": (funded: 220.0, total: 299.95),   // Staub Dutch Oven
        "181543":  (funded: 90.0,  total: 180.0)     // Staub Skillet
    ]

    var currentRegistry: Registry? {
        registries.first { $0.id == selectedRegistryId } ?? registries.first
    }
    
    var isActiveRegistry: Bool {
        !registries.isEmpty
    }
    
    // MARK: - Create
    
    func createRegistry(firstName: String,
                        lastName: String,
                        event: RegistryEvent,
                        date: Date,
                        budget: Double? = nil) {
        
        let newRegistry = Registry(
            id: UUID(),
            firstName: firstName,
            lastName: lastName,
            event: event,
            date: date,
            items: [],
            budget: budget
        )
        
        registries.append(newRegistry)
        selectedRegistryId = newRegistry.id
    }
    
    // MARK: - Selection
    
    func selectRegistry(_ id: UUID) {
        selectedRegistryId = id
    }
    
    // MARK: - Budget
    
    func setBudget(_ budget: Double) {
        guard let id = selectedRegistryId ?? registries.first?.id,
              let index = registries.firstIndex(where: { $0.id == id }) else { return }
        
        var registry = registries[index]
        registry.budget = budget
        registries[index] = registry
    }
    
    // MARK: - Actions
    
    func addProduct(_ product: ProductItem, to registryId: UUID? = nil) {
        let targetId = registryId ?? selectedRegistryId ?? registries.first?.id
        guard let id = targetId,
              let index = registries.firstIndex(where: { $0.id == id }) else { return }
        
        var registry = registries[index]
        let price = product.price ?? 0.0
        
        if let itemIndex = registry.items.firstIndex(where: { $0.id == product.id }) {
            registry.items[itemIndex].quantity += 1
        } else {
            registry.items.append(
                RegistryItem(
                    id: product.id,
                    title: product.title,
                    price: price,
                    imageUrl: product.path,
                    quantity: 1
                )
            )
        }
        
        registries[index] = registry
    }
    
    func deleteRegistry(_ id: UUID) {
        registries.removeAll { $0.id == id }
        if selectedRegistryId == id {
            selectedRegistryId = registries.first?.id
        }
    }
    
    func removeItem(_ productId: String, from registryId: UUID) {
        guard let index = registries.firstIndex(where: { $0.id == registryId }) else { return }
        var registry = registries[index]
        registry.items.removeAll { $0.id == productId }
        registries[index] = registry
    }
    
    func updateQty(_ productId: String, registryId: UUID, increment: Bool) {
        guard let index = registries.firstIndex(where: { $0.id == registryId }) else { return }
        var registry = registries[index]
        
        if let itemIndex = registry.items.firstIndex(where: { $0.id == productId }) {
            if increment {
                registry.items[itemIndex].quantity += 1
            } else {
                if registry.items[itemIndex].quantity > 1 {
                    registry.items[itemIndex].quantity -= 1
                } else {
                    registry.items.remove(at: itemIndex)
                }
            }
            registries[index] = registry
        }
    }

    // MARK: - Guest Gifting

    /// Deterministic share code derived from registry UUID (first 8 hex chars, uppercased).
    var shareCode: String {
        guard let registry = currentRegistry else { return "DEMO1234" }
        return String(registry.id.uuidString.prefix(8)).uppercased()
    }

    /// Records a full purchase by a guest: marks item purchased, fires notification.
    func recordPurchase(gift: GuestGift) {
        let notification = CoupleNotification(
            itemTitle: itemTitle(for: gift.itemId),
            guestName: gift.guestName,
            isContribution: gift.isContribution
        )
        notifications.insert(notification, at: 0)

        guard let regIdx = registries.firstIndex(where: { $0.id == gift.registryId }) else { return }
        if let itemIdx = registries[regIdx].items.firstIndex(where: { $0.id == gift.itemId }) {
            if gift.isContribution {
                // Update group funding
                let current = groupGiftData[gift.itemId] ?? (funded: 0, total: registries[regIdx].items[itemIdx].price)
                groupGiftData[gift.itemId] = (
                    funded: min(current.total, current.funded + gift.contributionAmount),
                    total:  current.total
                )
            } else {
                // Full purchase
                registries[regIdx].items[itemIdx].isPurchased = true
            }
        }
    }

    /// Mark an item as a group gift with a target total (couple action).
    func setGroupGift(itemId: String, total: Double) {
        groupGiftData[itemId] = (funded: groupGiftData[itemId]?.funded ?? 0, total: total)
    }

    var unreadNotificationCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    func markAllNotificationsRead() {
        for i in notifications.indices {
            notifications[i].isRead = true
        }
    }

    private func itemTitle(for itemId: String) -> String {
        currentRegistry?.items.first(where: { $0.id == itemId })?.title ?? "item"
    }
}
