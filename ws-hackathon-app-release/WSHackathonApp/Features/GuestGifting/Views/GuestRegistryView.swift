//
//  GuestRegistryView.swift
//  WSHackathonApp
//

import SwiftUI

struct GuestRegistryView: View {
    let registry: Registry
    @EnvironmentObject var registryRepo: RegistryRepository
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFilter: GuestFilter = .mostGiftable
    @State private var selectedItem: GiftabilityItem? = nil
    @State private var showDetail = false

    private var sortedItems: [GiftabilityItem] {
        let all = GiftabilityEngine.sortedItems(
            from: registry.items.filter { !$0.isPurchased },
            groupData: registryRepo.groupGiftData
        )
        return GiftabilityEngine.filtered(all, by: selectedFilter)
    }

    private var purchasedCount: Int {
        registry.items.filter { $0.isPurchased }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // No-login banner
                    noLoginBanner
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)

                    // Registry header card
                    registryHeaderCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                    // Filter chips
                    filterRow
                        .padding(.bottom, 16)

                    // Items
                    if sortedItems.isEmpty {
                        emptyFilterState
                            .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(sortedItems) { giftItem in
                                GiftabilityItemCard(
                                    item: giftItem,
                                    onBuyNow: {
                                        selectedItem = giftItem
                                        showDetail = true
                                    },
                                    onContribute: {
                                        selectedItem = giftItem
                                        showDetail = true
                                    }
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
            .background(Color.wsBackground.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(Color.wsNavy)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Guest View")
                        .font(WSFont.subheading(16))
                        .foregroundStyle(Color.wsNavy)
                }
            }
            .navigationDestination(isPresented: $showDetail) {
                if let item = selectedItem {
                    GuestProductDetailView(
                        giftItem: item,
                        registry: registry
                    )
                    .environmentObject(registryRepo)
                }
            }
        }
    }

    // MARK: - Subviews

    private var noLoginBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.wsSuccess)
            Text("No account required • Gift in seconds")
                .font(WSFont.body(13))
                .foregroundStyle(Color.wsSuccess)
                .fontWeight(.medium)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.wsSuccess.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.wsSuccess.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var registryHeaderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(registry.event.title.uppercased())
                    .font(WSFont.label(10))
                    .tracking(2)
                    .foregroundStyle(Color.wsAccent)
                Text(registry.displayName)
                    .font(WSFont.heading(22))
                    .foregroundStyle(Color.wsNavy)
                Text(registry.date.formatted(date: .long, time: .omitted))
                    .font(WSFont.body(13))
                    .foregroundStyle(Color.wsTextSecondary)
            }

            Divider().opacity(0.15)

            HStack(spacing: 0) {
                statPill(value: "\(registry.items.count)", label: "Items")
                Divider().frame(height: 32).opacity(0.2).padding(.horizontal, 16)
                statPill(value: "\(purchasedCount)", label: "Gifted")
                Divider().frame(height: 32).opacity(0.2).padding(.horizontal, 16)
                statPill(value: "\(registry.items.count - purchasedCount)", label: "Remaining")
                Spacer()
            }
        }
        .padding(18)
        .background(WSCardBackground(cornerRadius: 16))
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(WSFont.subheading(20))
                .foregroundStyle(Color.wsNavy)
            Text(label)
                .font(WSFont.caption(11))
                .foregroundStyle(Color.wsTextSecondary)
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GuestFilter.allCases) { filter in
                    filterChip(filter)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func filterChip(_ filter: GuestFilter) -> some View {
        Button {
            withAnimation(WSAnimation.spring) {
                selectedFilter = filter
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: filter.icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(filter.rawValue)
                    .font(WSFont.caption(13))
                    .fontWeight(.semibold)
            }
            .foregroundStyle(selectedFilter == filter ? Color.white : Color.wsNavy)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                selectedFilter == filter
                    ? AnyShapeStyle(WSGradient.button)
                    : AnyShapeStyle(Color.wsBackground)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(
                        selectedFilter == filter ? Color.clear : Color.wsBorder,
                        lineWidth: 1
                    )
            )
            .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var emptyFilterState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Color.wsMuted)
            Text("No items match this filter")
                .font(WSFont.subheading(16))
                .foregroundStyle(Color.wsNavy)
            Text("Try a different category")
                .font(WSFont.body(14))
                .foregroundStyle(Color.wsTextSecondary)
        }
    }
}
