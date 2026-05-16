//
//  GuestGiftingModels.swift
//  WSHackathonApp
//

import Foundation
import SwiftUI

// MARK: - Giftability Badge

enum GiftabilityBadge {
    case high, medium, premium

    var label: String {
        switch self {
        case .high:    return "Highly Giftable"
        case .medium:  return "Great Choice"
        case .premium: return "Premium Gift"
        }
    }

    var emoji: String {
        switch self {
        case .high:    return "🔥"
        case .medium:  return "⭐"
        case .premium: return "💎"
        }
    }

    var color: Color {
        switch self {
        case .high:    return Color(red: 0.90, green: 0.38, blue: 0.20)
        case .medium:  return Color(red: 0.55, green: 0.38, blue: 0.28)
        case .premium: return Color(red: 0.35, green: 0.25, blue: 0.55)
        }
    }

    var backgroundColor: Color {
        switch self {
        case .high:    return Color(red: 1.0, green: 0.93, blue: 0.88)
        case .medium:  return Color(red: 0.97, green: 0.93, blue: 0.90)
        case .premium: return Color(red: 0.93, green: 0.90, blue: 0.98)
        }
    }
}

// MARK: - Giftability Item

struct GiftabilityItem: Identifiable {
    let item: RegistryItem
    let score: Double
    let badge: GiftabilityBadge
    var groupFunded: Double?
    var groupTotal: Double?

    var id: String { item.id }

    var isGroupGift: Bool { groupTotal != nil }

    var fundingProgress: Double {
        guard let funded = groupFunded, let total = groupTotal, total > 0 else { return 0 }
        return min(1.0, funded / total)
    }

    var remainingAmount: Double? {
        guard let funded = groupFunded, let total = groupTotal else { return nil }
        return max(0, total - funded)
    }

    var isNearlyFunded: Bool {
        fundingProgress >= 0.6
    }

    var socialProof: String {
        switch badge {
        case .high:    return "Popular with wedding guests"
        case .medium:  return "A thoughtful & practical gift"
        case .premium: return "A luxurious keepsake gift"
        }
    }
}

// MARK: - Guest Filter

enum GuestFilter: String, CaseIterable, Identifiable {
    case mostGiftable = "Most Giftable"
    case under50      = "Under $50"
    case under100     = "Under $100"
    case groupGifts   = "Group Gifts"
    case lastMinute   = "Last-Minute"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .mostGiftable: return "flame.fill"
        case .under50:      return "tag.fill"
        case .under100:     return "tag"
        case .groupGifts:   return "person.2.fill"
        case .lastMinute:   return "clock.fill"
        }
    }
}

// MARK: - Guest Gift

struct GuestGift {
    let registryId: UUID
    let itemId: String
    let contributionAmount: Double
    let guestName: String
    let message: String?
    let isPurchased: Bool
    let isContribution: Bool
}

// MARK: - Couple Notification

struct CoupleNotification: Identifiable {
    let id: UUID
    let message: String
    let itemTitle: String
    let guestName: String
    let timestamp: Date
    var isRead: Bool = false

    init(id: UUID = UUID(),
         itemTitle: String,
         guestName: String,
         isContribution: Bool = false) {
        self.id = id
        self.itemTitle = itemTitle
        self.guestName = guestName
        self.timestamp = Date()
        self.isRead = false
        if isContribution {
            self.message = "🎁 \(guestName) contributed to your \(itemTitle)"
        } else {
            self.message = "🎁 \(guestName) purchased your \(itemTitle)"
        }
    }
}
