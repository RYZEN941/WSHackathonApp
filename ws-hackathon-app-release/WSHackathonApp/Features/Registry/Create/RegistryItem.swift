//
//  RegistryItem.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import Foundation
struct RegistryItem: Identifiable {
    let id: String // productId
    let title: String
    let price: Double
    let imageUrl: String?
    var quantity: Int
    // Group gifting
    var groupFunded: Double? = nil   // amount already contributed
    var groupTotal: Double? = nil    // total item price when used as group gift
    var isPurchased: Bool = false    // true once a guest has fully purchased
}
