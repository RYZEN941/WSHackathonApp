//
//  RegistryView.swift
//  WSHackathonApp
//

import SwiftUI

enum RegistryRoute: Hashable {
    case create
    case success
    case smartRegistry
}

struct RegistryView: View {
    @StateObject private var viewModel = RegistryViewModel()
    @EnvironmentObject var registryRepo: RegistryRepository
    @EnvironmentObject var cartRepo: CartRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    
    @State private var showRegistryDetail = false
    
    private let rowInsets = EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20)
    
    var body: some View {
        NavigationStack(path: $tabBarVM.registryPath) {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.hasRegistry {
                        if showRegistryDetail {
                            registryContent
                                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                      removal: .move(edge: .trailing).combined(with: .opacity)))
                        } else {
                            VStack(spacing: 20) {
                                ForEach(viewModel.registries) { registry in
                                    registryDashboardView(for: registry)
                                }
                            }
                            .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                                                  removal: .move(edge: .leading).combined(with: .opacity)))
                        }
                    } else {
                        noRegistryContent
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color.wsBackground.ignoresSafeArea())
            .navigationTitle(showRegistryDetail ? viewModel.displayTitle : AppStrings.Registry.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                    if showRegistryDetail {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Delete", role: .destructive) {
                                withAnimation(WSAnimation.spring) {
                                    viewModel.deleteRegistry(using: registryRepo)
                                    showRegistryDetail = false
                                }
                            }
                            .font(WSFont.body(15))
                        }
                    } else {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                tabBarVM.registryPath.append(.create)
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Color.wsNavy)
                            }
                        }
                    }
                    
                    if showRegistryDetail {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                withAnimation(WSAnimation.spring) {
                                    showRegistryDetail = false
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Color.wsNavy)
                            }
                    }
                }
            }
            .navigationDestination(for: RegistryRoute.self) { route in
                switch route {
                case .create:
                    CreateRegistryView()
                case .success:
                    RegistrySuccessView()
                case .smartRegistry:
                    SmartRegistryView()
                }
            }
        }
        .onAppear {
            viewModel.bind(repository: registryRepo)
        }
        .animation(WSAnimation.spring, value: viewModel.hasRegistry)
        .animation(WSAnimation.spring, value: showRegistryDetail)
    }
}

// MARK: - Components
private extension RegistryView {
    
    @ViewBuilder
    var registryContent: some View {
        VStack(spacing: 0) {
            // MARK: - Header with AI Button and Budget
            VStack(spacing: 16) {
                aiGiftFinderButton
                
                if viewModel.hasBudget {
                    budgetProgressView
                }
            }
            .padding(.vertical, 16)
            
            if viewModel.hasItems {
                registryItemsList
            } else {
                emptyItemsView
            }
        }
    }
    
    var registryItemsList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.items) { item in
                RegistryItemRow(
                    viewModel: RegistryItemRowViewModel(
                        item: item,
                        registryRepo: registryRepo,
                        cartRepo: cartRepo,
                        tabbarVM: tabBarVM
                    )
                )
                .padding(12)
                .background(WSCardBackground(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.wsNavy.opacity(0.06), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    var emptyItemsView: some View {
        WSEmptyState(
            title: "Your Registry is Empty",
            systemImage: "gift",
            message: "Browse our collection and tap the gift icon to add favorites.",
            buttonTitle: "Browse Collection",
            action: { tabBarVM.selectTab(.home) }
        )
    }
    
    @ViewBuilder
    func registryDashboardView(for registry: Registry) -> some View {
        Button {
            withAnimation(WSAnimation.spring) {
                registryRepo.selectRegistry(registry.id)
                showRegistryDetail = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                // Header Section
                VStack(alignment: .leading, spacing: 4) {
                    Text(registry.date.formatted(date: .abbreviated, time: .omitted))
                        .font(WSFont.caption(12))
                        .foregroundStyle(Color.wsAccent)
                        .fontWeight(.medium)
                    
                    Text(registry.displayName)
                        .font(WSFont.subheading(20))
                        .foregroundStyle(Color.wsNavy)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Divider()
                    .padding(.horizontal, 20)
                    .opacity(0.1)
                
                // Info Section
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(registry.items.count)")
                            .font(WSFont.subheading(20))
                            .foregroundStyle(Color.wsNavy)
                        Text("Items")
                            .font(WSFont.caption(12))
                            .foregroundStyle(Color.wsTextSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("$\(String(format: "%.0f", registry.totalValue))")
                            .font(WSFont.subheading(20))
                            .foregroundStyle(Color.wsNavy)
                        Text("Total Value")
                            .font(WSFont.caption(12))
                            .foregroundStyle(Color.wsTextSecondary)
                    }
                    
                    if let budget = registry.budget {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("$\(String(format: "%.0f", budget))")
                                .font(WSFont.subheading(20))
                                .foregroundStyle(Color.wsAccent)
                            Text("Budget")
                                .font(WSFont.caption(12))
                                .foregroundStyle(Color.wsTextSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.wsMuted)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.wsCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.wsBorder.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 20)
    }

    var noRegistryContent: some View {
        VStack(spacing: 0) {
            WSRegistryHeroCard {
                tabBarVM.registryPath.append(.create)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            WSSectionHeader(
                title: "Top Reasons to Register",
                subtitle: "Everything you need for your special day"
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            ForEach(Array(viewModel.instructions.enumerated()), id: \.element.id) { index, item in
                RegistryReasonCard(
                    number: index + 1,
                    title: item.title,
                    description: item.description
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .padding(.bottom, 40)
    }
    
    var aiGiftFinderButton: some View {
        Button {
            tabBarVM.registryPath.append(.smartRegistry)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.3, green: 0.2, blue: 0.5), Color(red: 0.5, green: 0.35, blue: 0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "sparkles")
                        .font(.body)
                        .foregroundColor(.yellow)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(AppStrings.SmartRegistry.aiGiftFinder)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Get AI-curated gift bundles within your budget")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color(red: 0.35, green: 0.25, blue: 0.55).opacity(0.15), radius: 6, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 0.35, green: 0.25, blue: 0.55).opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }
    
    var budgetProgressView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Registry Budget")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let remaining = viewModel.remainingBudget {
                    Text("$\(String(format: "%.2f", remaining)) remaining")
                        .font(.caption)
                        .foregroundColor(remaining > 0 ? .green : .red)
                        .fontWeight(.medium)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 10)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: viewModel.budgetProgress > 0.9
                                    ? [.red, .orange]
                                    : [Color(red: 0.3, green: 0.2, blue: 0.5), Color(red: 0.5, green: 0.35, blue: 0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, min(geometry.size.width, geometry.size.width * viewModel.budgetProgress)), height: 10)
                        .animation(.spring(response: 0.5), value: viewModel.budgetProgress)
                }
            }
            .frame(height: 10)
            
            HStack {
                Text("$\(String(format: "%.2f", viewModel.totalRegistryValue))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let budget = viewModel.budget {
                    Text("$\(String(format: "%.2f", budget))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 16)
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
