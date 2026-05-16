//
//  SmartRegistryView.swift
//  WSHackathonApp
//
//  AI-powered gift discovery wizard for registry.
//  Step 1: Set budget → Step 2: Select categories → Step 3: View generated bundles
//

import SwiftUI

struct SmartRegistryView: View {
    
    @StateObject private var viewModel = SmartRegistryViewModel()
    @EnvironmentObject var registryRepo: RegistryRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    
    @State private var showAddedConfirmation = false
    @State private var addedBundleName = ""
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - AI Header
                    aiHeader
                    
                    // MARK: - Occasion Badge
                    occasionBadge
                    
                    // MARK: - Budget Section
                    budgetSection
                    
                    // MARK: - Category Selection
                    categorySection
                    
                    // MARK: - Generate Button
                    generateButton
                    
                    // MARK: - Results
                    if viewModel.isGenerating {
                        generatingView
                    } else if viewModel.hasGenerated {
                        if viewModel.giftBundles.isEmpty {
                            noBundlesView
                        } else {
                            bundlesSection
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 8)
            }
            
            // MARK: - Added Confirmation Overlay
            if showAddedConfirmation {
                confirmationOverlay
            }
        }
        .navigationTitle(AppStrings.SmartRegistry.aiGiftFinder)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let event = registryRepo.currentRegistry?.event {
                viewModel.bind(registryRepo: registryRepo, occasion: event)
            }
        }
    }
}

// MARK: - Components

private extension SmartRegistryView {
    
    // MARK: - AI Header
    
    var aiHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.yellow)
                    .symbolEffect(.pulse)
                
                Text("Smart Gift Discovery")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text("Tell us your budget and preferences, and our AI will create curated gift bundles just for you.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Occasion Badge
    
    var occasionBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "gift.fill")
                .font(.caption)
            Text(viewModel.occasionText)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.35, green: 0.25, blue: 0.45)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }
    
    // MARK: - Budget Section
    
    var budgetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(AppStrings.SmartRegistry.setYourBudget)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(viewModel.budgetText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.35, green: 0.25, blue: 0.55))
            }
            
            // Budget Slider
            Slider(value: $viewModel.budget, in: 25...1000, step: 25)
                .tint(Color(red: 0.35, green: 0.25, blue: 0.55))
            
            // Budget Presets
            HStack(spacing: 8) {
                ForEach(viewModel.budgetPresets, id: \.self) { preset in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.budget = preset
                        }
                    }) {
                        Text("$\(Int(preset))")
                            .font(.caption)
                            .fontWeight(viewModel.budget == preset ? .bold : .medium)
                            .foregroundColor(viewModel.budget == preset ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.budget == preset
                                ? Color(red: 0.35, green: 0.25, blue: 0.55)
                                : Color(.systemGray5)
                            )
                            .cornerRadius(20)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Category Section
    
    var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppStrings.SmartRegistry.selectCategories)
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Select categories you're interested in, or leave empty for all.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Category chips in wrapped layout
            FlowLayout(spacing: 8) {
                ForEach(viewModel.availableCategories, id: \.self) { category in
                    categoryChip(category)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
    
    func categoryChip(_ category: String) -> some View {
        let isSelected = viewModel.isCategorySelected(category)
        
        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                viewModel.toggleCategory(category)
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                Text(category)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected
                ? Color(red: 0.35, green: 0.25, blue: 0.55)
                : Color(.systemGray6)
            )
            .cornerRadius(24)
        }
    }
    
    // MARK: - Generate Button
    
    var generateButton: some View {
        Button(action: {
            Task {
                await viewModel.generateBundles()
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.body)
                Text(AppStrings.SmartRegistry.generateBundles)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.4, green: 0.3, blue: 0.55)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
        }
        .disabled(viewModel.isGenerating)
        .opacity(viewModel.isGenerating ? 0.6 : 1)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Generating View
    
    var generatingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(AppStrings.SmartRegistry.generatingBundles)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Shimmer placeholders
            VStack(spacing: 12) {
                ForEach(0..<2, id: \.self) { _ in
                    ShimmerView()
                        .frame(height: 160)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 8)
    }
    
    // MARK: - No Bundles View
    
    var noBundlesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text(AppStrings.SmartRegistry.noBundlesMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Bundles Section
    
    var bundlesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Curated Bundles")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(viewModel.giftBundles.count) options")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            
            ForEach(viewModel.giftBundles) { bundle in
                bundleCard(bundle)
            }
        }
    }
    
    func bundleCard(_ bundle: GiftBundleDisplay) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Bundle header
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "gift.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Text(bundle.themeName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("$\(bundle.totalPrice, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Text(bundle.themeDescription)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.15, green: 0.15, blue: 0.22), Color(red: 0.3, green: 0.22, blue: 0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // Products in bundle
            VStack(spacing: 0) {
                ForEach(bundle.products) { product in
                    bundleProductRow(product, bundle: bundle)
                    
                    if product.id != bundle.products.last?.id {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(Color.white)
            
            // Budget check
            if bundle.totalPrice <= viewModel.budget {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Within budget — $\(String(format: "%.2f", viewModel.budget - bundle.totalPrice)) remaining")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.08))
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("$\(String(format: "%.2f", bundle.totalPrice - viewModel.budget)) over budget")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.08))
            }
            
            // Add Bundle Button
            Button(action: {
                viewModel.addBundleToRegistry(bundle)
                addedBundleName = bundle.themeName
                withAnimation(.spring(response: 0.4)) {
                    showAddedConfirmation = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showAddedConfirmation = false
                    }
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.subheadline)
                    Text(AppStrings.SmartRegistry.addBundleToRegistry)
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color.black)
                .cornerRadius(12)
            }
            .padding(16)
        }
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
    
    func bundleProductRow(_ product: ProductItem, bundle: GiftBundleDisplay) -> some View {
        HStack(spacing: 12) {
            CustomAsyncImage(url: product.imageURL)
                .frame(width: 56, height: 56)
                .cornerRadius(8)
                .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                if let price = product.price {
                    Text("$\(price, specifier: "%.2f")")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    viewModel.removeBundleItem(product, from: bundle)
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.body)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    // MARK: - Confirmation Overlay
    
    var confirmationOverlay: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Added to Registry!")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\"\(addedBundleName)\" bundle added")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.9))
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - Flow Layout for category chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(subviews: subviews, proposal: proposal)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(subviews: subviews, proposal: proposal)
        
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }
    
    private func layout(subviews: Subviews, proposal: ProposedViewSize) -> (positions: [CGPoint], sizes: [CGSize], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            sizes.append(size)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
        
        return (positions, sizes, CGSize(width: maxWidth, height: currentY + lineHeight))
    }
}
