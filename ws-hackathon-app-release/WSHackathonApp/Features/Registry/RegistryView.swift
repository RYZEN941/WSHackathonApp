//
//  RegistryView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
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
                        }
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle(AppStrings.Registry.title)
            .navigationBarTitleDisplayMode(.inline)
            
            // MARK: - Navigation
            
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
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
    
    var createRegistryButton: some View {
        HStack(spacing: 12) {
            Image(systemName: AppImages.Registry.plus)
                .foregroundColor(.black)
            Text(AppStrings.Registry.create)
                .font(.headline)
                .foregroundColor(.black)
            Spacer()
            Image(systemName: AppImages.Registry.chevron)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    var instructionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Text(AppStrings.Registry.topReasons)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(viewModel.instructions.enumerated()), id: \.element.id) { index, item in
                    instructionRow(
                        title: item.title,
                        description: item.description
                    )
                    if index != viewModel.instructions.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
    
    func instructionRow(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }
    
    var emptyItemsView: some View {
        Text(AppStrings.Registry.noItemsAdded)
            .foregroundColor(.gray)
            .padding()
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
            }
        }
        .padding(.horizontal, 16)
    }
    
    var registryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            Text(viewModel.displayTitle)
                .font(.headline)
            
            Text(viewModel.displayDate)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Button("Delete Registry") {
                viewModel.deleteRegistry(using: registryRepo)
            }
            .font(.caption)
            .foregroundColor(.red)
            .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}
