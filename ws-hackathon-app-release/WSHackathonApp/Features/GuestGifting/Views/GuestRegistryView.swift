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
    @State private var showCollaborators = false

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
            ZStack {
                Color.wsBackground
                    .ignoresSafeArea()
                
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
                            VStack(spacing: 14) {
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
            }
            .navigationTitle("Guest View")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.wsBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.wsNavy)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCollaborators = true
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                                .shadow(color: Color.green.opacity(0.8), radius: 3)
                            
                            CollaborationFacepileView()
                        }
                        .padding(.leading, 8)
                        .padding(.trailing, 4)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.wsControlFill.opacity(0.7)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationDestination(isPresented: $showDetail) {
                if let item = selectedItem {
                    GuestProductDetailView(
                        giftItem: item,
                        registry: registry,
                        onDone: { showDetail = false }
                    )
                    .environmentObject(registryRepo)
                }
            }
            .sheet(isPresented: $showCollaborators) {
                collaboratorsSheet
            }
        }
    }

    // MARK: - Collaborators Sheet

    private var collaboratorsSheet: some View {
        let facepileUsers: [FacepileUser] = [
            FacepileUser(name: "Alex Miller", initials: "AM", color: Color(red: 0.76, green: 0.60, blue: 0.42)),
            FacepileUser(name: "Taylor Swift", initials: "TS", color: Color(red: 0.08, green: 0.18, blue: 0.36)),
            FacepileUser(name: "Jordan Smith", initials: "JS", color: Color(red: 0.18, green: 0.36, blue: 0.27)),
            FacepileUser(name: "Morgan Jones", initials: "MJ", color: Color(red: 0.48, green: 0.12, blue: 0.24)),
            FacepileUser(name: "Casey Davis", initials: "CD", color: Color(red: 0.36, green: 0.24, blue: 0.48))
        ]
        return NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .shadow(color: Color.green.opacity(0.8), radius: 4)
                    Text("\(facepileUsers.count) people viewing this registry")
                        .font(WSFont.caption(12))
                        .foregroundStyle(Color.wsTextSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)

                Divider().opacity(0.12)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(facepileUsers) { user in
                            HStack(spacing: 14) {
                                Text(user.initials)
                                    .font(WSFont.label(13))
                                    .bold()
                                    .foregroundStyle(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Circle().fill(user.color))
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                    .shadow(color: Color.black.opacity(0.1), radius: 4)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.name)
                                        .font(WSFont.subheading(15))
                                        .foregroundStyle(Color.wsNavy)
                                    Text("Currently browsing")
                                        .font(WSFont.caption(12))
                                        .foregroundStyle(Color.wsTextSecondary)
                                }

                                Spacer()

                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: Color.green.opacity(0.6), radius: 3)
                            }
                            .padding(14)
                            .background(Color.wsSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.wsBorder.opacity(0.5), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .background(Color.wsBackground.ignoresSafeArea())
            .navigationTitle("Active Viewers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showCollaborators = false }
                        .font(WSFont.body(16))
                        .foregroundStyle(Color.wsNavy)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
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
            selectedFilter = filter
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
