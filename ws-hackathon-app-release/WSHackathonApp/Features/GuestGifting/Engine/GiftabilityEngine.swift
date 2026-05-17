//
//  GiftabilityEngine.swift
//  WSHackathonApp
//

import Foundation

/// Pure value-type engine that computes a 0–100 giftability score for registry items.
///
/// Formula:
///   40% price attractiveness
///   30% popularity proxy (seeded deterministically from item.id for demo consistency)
///   20% completion urgency (group gift funding progress)
///   10% trend proxy (seeded from item.id)
struct GiftabilityEngine {

    // MARK: - Public API

    static func score(for item: RegistryItem,
                      groupFunded: Double? = nil,
                      groupTotal: Double? = nil) -> Double {
        let price       = priceAttractiveness(item.price)       // 0–1
        let popularity  = popularityProxy(item.id)              // 0–1
        let completion  = completionUrgency(funded: groupFunded, total: groupTotal) // 0–1
        let trend       = trendProxy(item.id)                   // 0–1

        return (price * 0.40 + popularity * 0.30 + completion * 0.20 + trend * 0.10) * 100
    }

    static func badge(for score: Double) -> GiftabilityBadge {
        if score >= 68 { return .high }
        if score >= 42 { return .medium }
        return .premium
    }

    /// Returns items wrapped as GiftabilityItems, sorted highest score first.
    static func sortedItems(from items: [RegistryItem],
                            groupData: [String: (funded: Double, total: Double)]) -> [GiftabilityItem] {
        items
            .map { item in
                let gd = groupData[item.id]
                let s  = score(for: item, groupFunded: gd?.funded, groupTotal: gd?.total)
                return GiftabilityItem(
                    item: item,
                    score: s,
                    badge: badge(for: s),
                    groupFunded: gd?.funded,
                    groupTotal: gd?.total
                )
            }
            .sorted { $0.score > $1.score }
    }

    /// Filter + sort for a given GuestFilter selection.
    static func filtered(_ items: [GiftabilityItem], by filter: GuestFilter) -> [GiftabilityItem] {
        switch filter {
        case .mostGiftable:
            return items.sorted { $0.score > $1.score }
        case .under50:
            return items.filter { $0.item.price < 50 }.sorted { $0.score > $1.score }
        case .under100:
            return items.filter { $0.item.price < 100 }.sorted { $0.score > $1.score }
        case .groupGifts:
            return items.filter { $0.isGroupGift }.sorted { ($0.groupFunded ?? 0) > ($1.groupFunded ?? 0) }
        case .lastMinute:
            return items.filter { $0.item.price < 75 }.sorted { $0.item.price < $1.item.price }
        }
    }

    // MARK: - Private Helpers

    private static func priceAttractiveness(_ price: Double) -> Double {
        switch price {
        case ..<30:    return 1.00
        case ..<60:    return 0.90
        case ..<100:   return 0.78
        case ..<175:   return 0.60
        case ..<300:   return 0.42
        default:       return 0.22
        }
    }

    /// Seeded deterministically from item ID so results are stable across launches.
    private static func popularityProxy(_ itemId: String) -> Double {
        let hash = abs(itemId.hash &* 0x517CC1B727220A95)
        return Double(hash % 100) / 100.0
    }

    private static func completionUrgency(funded: Double?, total: Double?) -> Double {
        guard let funded, let total, total > 0 else { return 0.30 }
        let progress = funded / total
        switch progress {
        case 0.85...: return 1.00
        case 0.65...: return 0.85
        case 0.45...: return 0.65
        default:      return 0.40
        }
    }

    private static func trendProxy(_ itemId: String) -> Double {
        let hash = abs(itemId.hash &* 6_364_136_223_846_793_005)
        return Double(hash % 100) / 100.0
    }
}
