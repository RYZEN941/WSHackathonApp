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
    
    // MARK: - Mock Collaboration Users
    
    struct MockUser: Identifiable, Hashable {
        let id: String
        let name: String
        let avatar: String
    }
    
    static let mockUser1 = MockUser(id: "user1", name: "tester1 (User 1)", avatar: "person.circle.fill")
    static let mockUser2 = MockUser(id: "user2", name: "Tester2 (User 2)", avatar: "person.circle")
    
    @Published var currentUser: MockUser = mockUser1
    
    // User registry maps (frontend state storage)
    private var user1RegistryIds: [UUID] = []
    private var user2RegistryIds: [UUID] = []
    private var globalRegistryCache: [UUID: Registry] = [:]
    
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
    
    // MARK: - Initializer & Seeding
    
    init() {
        // Seed default registry for User 1 to make it immediately visual and impressive
        let seedId = UUID()
        let seedRegistry = Registry(
            id: seedId,
            firstName: "Alex & Jordan",
            lastName: "Wedding",
            event: .wedding,
            date: Date().addingTimeInterval(86400 * 90), // 90 days from now
            items: [
                RegistryItem(
                    id: "2505456",
                    title: "Williams Sonoma End-Grain Cutting Board, Acacia",
                    price: 129.95,
                    imageUrl: "https://images.unsplash.com/photo-1594756114149-aa32364affc9?auto=format&fit=crop&q=80&w=600&h=600",
                    quantity: 1
                ),
                RegistryItem(
                    id: "2453926",
                    title: "Staub Enameled Cast Iron Round Dutch Oven",
                    price: 299.95,
                    imageUrl: "https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?auto=format&fit=crop&q=80&w=600&h=600",
                    quantity: 1
                )
            ],
            budget: 1000.0
        )
        
        globalRegistryCache[seedId] = seedRegistry
        user1RegistryIds = [seedId]
        
        // Sync active user
        syncRegistries()
    }
    
    // MARK: - Sync & Switch
    
    func syncRegistries() {
        let activeIds = currentUser.id == "user1" ? user1RegistryIds : user2RegistryIds
        self.registries = activeIds.compactMap { globalRegistryCache[$0] }
        
        // Update selection if invalid or missing
        if let currentSel = selectedRegistryId, activeIds.contains(currentSel) {
            // Keep selection
        } else {
            selectedRegistryId = registries.first?.id
        }
    }
    
    func switchUser(to user: MockUser) {
        currentUser = user
        syncRegistries()
    }
    
    // MARK: - Join Collaboration Room
    
    func joinRegistry(by code: String) -> Bool {
        let cleanedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Search global cache for any registry matching the first 8 characters of UUID
        guard let matchingRegistry = globalRegistryCache.values.first(where: { reg in
            let regCode = String(reg.id.uuidString.prefix(8)).uppercased()
            return regCode == cleanedCode
        }) else {
            return false // Code not found
        }
        
        let registryId = matchingRegistry.id
        if currentUser.id == "user1" {
            if !user1RegistryIds.contains(registryId) {
                user1RegistryIds.append(registryId)
            }
        } else {
            if !user2RegistryIds.contains(registryId) {
                user2RegistryIds.append(registryId)
            }
        }
        
        syncRegistries()
        selectedRegistryId = registryId
        return true
    }
    
    // MARK: - Create
    
    func createRegistry(firstName: String,
                        lastName: String,
                        event: RegistryEvent,
                        date: Date,
                        budget: Double? = nil) {
        
        let newId = UUID()
        let newRegistry = Registry(
            id: newId,
            firstName: firstName,
            lastName: lastName,
            event: event,
            date: date,
            items: [],
            budget: budget
        )
        
        globalRegistryCache[newId] = newRegistry
        
        if currentUser.id == "user1" {
            user1RegistryIds.append(newId)
        } else {
            user2RegistryIds.append(newId)
        }
        
        syncRegistries()
        selectedRegistryId = newId
    }
    
    // MARK: - Selection
    
    func selectRegistry(_ id: UUID) {
        selectedRegistryId = id
    }
    
    // MARK: - Budget
    
    func setBudget(_ budget: Double) {
        guard let id = selectedRegistryId ?? registries.first?.id,
              var registry = globalRegistryCache[id] else { return }
        
        registry.budget = budget
        globalRegistryCache[id] = registry
        syncRegistries()
    }
    
    // MARK: - Actions
    
    func addProduct(_ product: ProductItem, to registryId: UUID? = nil) {
        let targetId = registryId ?? selectedRegistryId ?? registries.first?.id
        guard let id = targetId,
              var registry = globalRegistryCache[id] else { return }
        
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
        
        globalRegistryCache[id] = registry
        syncRegistries()
    }
    
    func deleteRegistry(_ id: UUID) {
        globalRegistryCache.removeValue(forKey: id)
        user1RegistryIds.removeAll { $0 == id }
        user2RegistryIds.removeAll { $0 == id }
        
        if selectedRegistryId == id {
            selectedRegistryId = nil
        }
        syncRegistries()
    }
    
    func removeItem(_ productId: String, from registryId: UUID) {
        guard var registry = globalRegistryCache[registryId] else { return }
        registry.items.removeAll { $0.id == productId }
        globalRegistryCache[registryId] = registry
        syncRegistries()
    }
    
    func updateQty(_ productId: String, registryId: UUID, increment: Bool) {
        guard var registry = globalRegistryCache[registryId] else { return }
        
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
            globalRegistryCache[registryId] = registry
            syncRegistries()
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

        guard var registry = globalRegistryCache[gift.registryId] else { return }
        if let itemIdx = registry.items.firstIndex(where: { $0.id == gift.itemId }) {
            if gift.isContribution {
                // Update group funding
                let current = groupGiftData[gift.itemId] ?? (funded: 0, total: registry.items[itemIdx].price)
                groupGiftData[gift.itemId] = (
                    funded: min(current.total, current.funded + gift.contributionAmount),
                    total:  current.total
                )
            } else {
                // Full purchase
                registry.items[itemIdx].isPurchased = true
            }
        }
        globalRegistryCache[gift.registryId] = registry
        syncRegistries()
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
