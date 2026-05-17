//
//  RegistryViewModel.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 05/04/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class RegistryViewModel: ObservableObject {
    
    @Published private(set) var registries: [Registry] = []
    @Published var selectedRegistryId: UUID?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Bind Repository
    
    func bind(repository: RegistryRepository) {
        repository.$registries
            .receive(on: RunLoop.main)
            .assign(to: &$registries)
        
        repository.$selectedRegistryId
            .receive(on: RunLoop.main)
            .assign(to: &$selectedRegistryId)
    }
    
    // MARK: - Computed
    
    var registry: Registry? {
        registries.first { $0.id == selectedRegistryId } ?? registries.first
    }

    var hasRegistry: Bool {
        !registries.isEmpty
    }
    
    var hasItems: Bool {
        !(registry?.items.isEmpty ?? true)
    }
    
    var items: [RegistryItem] {
        registry?.items ?? []
    }
    
    var displayTitle: String {
        registry?.displayName ?? ""
    }
    
    var displayDate: String {
        guard let date = registry?.date else { return "" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
    
    // MARK: - Budget
    
    var hasBudget: Bool {
        registry?.budget != nil
    }
    
    var budget: Double? {
        registry?.budget
    }
    
    var totalRegistryValue: Double {
        registry?.totalValue ?? 0
    }
    
    var remainingBudget: Double? {
        registry?.remainingBudget
    }
    
    var budgetProgress: Double {
        registry?.budgetProgress ?? 0
    }
    
    // MARK: - Instructions
    
    var instructions: [RegistryInstruction] {
        [
            RegistryInstruction(
                title: AppStrings.Registry.exclusiveProduct,
                description: AppStrings.Registry.exclusiveProductsDesc
            ),
            RegistryInstruction(
                title: AppStrings.Registry.expertAdvice,
                description: AppStrings.Registry.expertAdviceDesc
            ),
            RegistryInstruction(
                title: AppStrings.Registry.discountTitle,
                description: AppStrings.Registry.discountDesc
            ),
            RegistryInstruction(
                title: AppStrings.Registry.inStoreTitle,
                description: AppStrings.Registry.instStoreDesc
            )
        ]
    }
    
    // MARK: - Actions
    
    func deleteRegistry(using repository: RegistryRepository) {
        guard let id = selectedRegistryId ?? registries.first?.id else { return }
        repository.deleteRegistry(id)
    }
}

