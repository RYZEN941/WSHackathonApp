//
//  Registry.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import Foundation
struct Registry: Identifiable {
    let id: UUID
    let firstName: String
    let lastName: String
    let event: RegistryEvent
    let date: Date
    var items: [RegistryItem]
    var budget: Double?
    
    var displayName: String {
        "\(firstName) \(lastName) - \(event.title)"
    }
    
    var totalValue: Double {
        items.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }
    
    var remainingBudget: Double? {
        guard let budget = budget else { return nil }
        return max(0, budget - totalValue)
    }
    
    var budgetProgress: Double {
        guard let budget = budget, budget > 0 else { return 0 }
        return min(1.0, totalValue / budget)
    }
}

