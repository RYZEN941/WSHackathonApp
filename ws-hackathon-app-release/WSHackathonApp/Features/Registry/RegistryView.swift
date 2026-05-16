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

    private let rowInsets = EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20)

    var body: some View {
        NavigationStack(path: $tabBarVM.registryPath) {
            
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        
                        // MARK: - Header Image
                        GeometryReader { geometry in
                            Image(AppImages.Registry.header)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: 200)
                                .clipped()
                        }
                        .frame(height: 200)
                        
                        // MARK: - Content
                        VStack(spacing: 16) {
                            
                            if viewModel.hasRegistry {
                                
                                registryHeader
                                
                                // MARK: - AI Gift Finder Button
                                aiGiftFinderButton
                                
                                // MARK: - Budget Progress
                                if viewModel.hasBudget {
                                    budgetProgressView
                                }
                                
                                if viewModel.hasItems {
                                    registryItemsList
                                } else {
                                    emptyItemsView
                                }
                                
                            } else {
                                registryCard
                                instructionCard
                            }
//             Group {
//                 if viewModel.hasRegistry {
//                     registryContent
//                 } else {
//                     noRegistryContent
//                 }
//             }
//             .frame(maxWidth: .infinity, maxHeight: .infinity)
//             .wsAppBackground()
//             .navigationTitle(viewModel.hasRegistry ? viewModel.displayTitle : AppStrings.Registry.title)
//             .navigationBarTitleDisplayMode(.large)
//             .toolbar {
//                 if viewModel.hasRegistry {
//                     ToolbarItem(placement: .topBarTrailing) {
//                         Button("Delete", role: .destructive) {
//                             viewModel.deleteRegistry(using: registryRepo)
                        }
                        .font(WSFont.body(15))
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
//                 case .create: CreateRegistryView()
//                 case .success: RegistrySuccessView()
                }
            }
        }
        .onAppear {
            viewModel.bind(repository: registryRepo)
        }
    }

// MARK: - Components
private extension RegistryView {
    
    // MARK: - AI Gift Finder Button
    
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
    
    // MARK: - Budget Progress
    
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
            
            // Progress Bar
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
                        .frame(width: geometry.size.width * viewModel.budgetProgress, height: 10)
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
    
    var registryCard: some View {
        VStack(spacing: 0) {
            
            Button {
                tabBarVM.registryPath.append(.create)
            } label: {
                createRegistryButton
                    .contentShape(Rectangle())
//     @ViewBuilder
//     private var registryContent: some View {
//         if viewModel.hasItems {
//             List {
//                 Section {
//                     ForEach(viewModel.items) { item in
//                         RegistryItemRow(
//                             viewModel: RegistryItemRowViewModel(
//                                 item: item,
//                                 registryRepo: registryRepo,
//                                 cartRepo: cartRepo,
//                                 tabbarVM: tabBarVM
//                             )
//                         )
//                         .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
//                         .listRowBackground(WSCardBackground(cornerRadius: 12))
//                         .listRowSeparatorTint(Color.wsNavy.opacity(0.06))
//                         .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//                             Button(role: .destructive) {
//                                 withAnimation(WSAnimation.spring) {
//                                     registryRepo.removeItem(item.id)
//                                 }
//                             } label: {
//                                 Label("Delete", systemImage: "trash")
//                             }
//                         }
//                     }
//                 } header: {
//                     HStack {
//                         Label(viewModel.displayDate, systemImage: "calendar")
//                             .font(WSFont.body(13))
//                             .foregroundStyle(Color.wsTextSecondary)
//                             .lineLimit(1)
//                         Spacer(minLength: 8)
//                         Text("\(viewModel.items.count) Items")
//                             .font(WSFont.caption(12))
//                             .foregroundStyle(Color.wsAction)
//                     }
//                     .textCase(nil)
//                 }
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
