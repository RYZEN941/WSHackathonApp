//
//  Model.swift
//  WSHackathonApp
//

import Foundation

enum TabItem: Int, CaseIterable, Identifiable {
    case home = 0
    case registry
    case cart

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return AppStrings.Tabs.home
        case .registry: return AppStrings.Tabs.registry
        case .cart: return AppStrings.Tabs.cart
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .registry: return "gift"
        case .cart: return "bag"
        }
    }

    var iconFilled: String {
        switch self {
        case .home: return "house.fill"
        case .registry: return "gift.fill"
        case .cart: return "bag.fill"
        }
    }

    static func from(rawValue: Int) -> TabItem? {
        TabItem(rawValue: rawValue)
    }
}
