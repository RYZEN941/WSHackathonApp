//
//  RegistryView.swift
//  WSHackathonApp
//

import SwiftUI

enum RegistryRoute: Hashable {
    case create
    case success
}

struct RegistryView: View {

    @StateObject private var viewModel = RegistryViewModel()

    @EnvironmentObject var registryRepo: RegistryRepository
    @EnvironmentObject var cartRepo: CartRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel

    private let rowInsets = EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20)

    var body: some View {
        NavigationStack(path: $tabBarVM.registryPath) {
            Group {
                if viewModel.hasRegistry {
                    registryContent
                } else {
                    noRegistryContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .wsAppBackground()
            .navigationTitle(viewModel.hasRegistry ? viewModel.displayTitle : AppStrings.Registry.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if viewModel.hasRegistry {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Delete", role: .destructive) {
                            viewModel.deleteRegistry(using: registryRepo)
                        }
                        .font(WSFont.body(15))
                    }
                }
            }
            .navigationDestination(for: RegistryRoute.self) { route in
                switch route {
                case .create: CreateRegistryView()
                case .success: RegistrySuccessView()
                }
            }
        }
        .onAppear {
            viewModel.bind(repository: registryRepo)
        }
    }

    @ViewBuilder
    private var registryContent: some View {
        if viewModel.hasItems {
            List {
                Section {
                    ForEach(viewModel.items) { item in
                        RegistryItemRow(
                            viewModel: RegistryItemRowViewModel(
                                item: item,
                                registryRepo: registryRepo,
                                cartRepo: cartRepo,
                                tabbarVM: tabBarVM
                            )
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(WSCardBackground(cornerRadius: 12))
                        .listRowSeparatorTint(Color.wsNavy.opacity(0.06))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation(WSAnimation.spring) {
                                    registryRepo.removeItem(item.id)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    HStack {
                        Label(viewModel.displayDate, systemImage: "calendar")
                            .font(WSFont.body(13))
                            .foregroundStyle(Color.wsTextSecondary)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text("\(viewModel.items.count) Items")
                            .font(WSFont.caption(12))
                            .foregroundStyle(Color.wsAction)
                    }
                    .textCase(nil)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        } else {
            WSEmptyState(
                title: "Your Registry is Empty",
                systemImage: "gift",
                message: "Browse our collection and tap the gift icon to add favorites.",
                buttonTitle: "Browse Collection",
                action: { tabBarVM.selectTab(.home) }
            )
        }
    }

    /// List-based layout so content respects safe area and never overflows horizontally.
    private var noRegistryContent: some View {
        List {
            Section {
                WSRegistryHeroCard {
                    tabBarVM.registryPath.append(.create)
                }
                .listRowInsets(rowInsets)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            Section {
                ForEach(Array(viewModel.instructions.enumerated()), id: \.element.id) { index, item in
                    RegistryReasonCard(
                        number: index + 1,
                        title: item.title,
                        description: item.description
                    )
                    .listRowInsets(rowInsets)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            } header: {
                WSSectionHeader(
                    title: "Top Reasons to Register",
                    subtitle: "Everything you need for your special day"
                )
                .textCase(nil)
                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
            }
        }
        .listStyle(.plain)
        .listSectionSpacing(12)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
}

// MARK: - Reason Card

private struct RegistryReasonCard: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(WSFont.subheading(13))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(WSGradient.button)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(WSFont.subheading(15))
                    .foregroundStyle(Color.wsNavy)

                Text(description)
                    .font(WSFont.body(13))
                    .foregroundStyle(Color.wsTextSecondary)
            }
        }
        .padding(14)
        .wsCard(cornerRadius: 14)
    }
}
