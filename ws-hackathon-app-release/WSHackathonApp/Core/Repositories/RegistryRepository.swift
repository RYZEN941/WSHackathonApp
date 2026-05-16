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
}
