//
//  SmartRegistryView.swift
//  WSHackathonApp
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
            Color.wsBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
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
                .padding(.top, 16)
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
    
    var aiHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(WSGradient.button)
                    .symbolEffect(.pulse)
                
                Text("Smart Gift Discovery")
                    .font(WSFont.heading(22))
                    .foregroundStyle(Color.wsNavy)
            }
            
            Text("Our AI analyzes our catalog to create curated gift bundles within your budget and style preferences.")
                .font(WSFont.body(14))
                .foregroundStyle(Color.wsTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 8)
    }
    
    var occasionBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "gift.fill")
                .font(.caption)
            Text(viewModel.occasionText.uppercased())
                .font(WSFont.caption(11))
                .tracking(1.5)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(WSGradient.button)
        .clipShape(Capsule())
    }
    
    var budgetSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(AppStrings.SmartRegistry.setYourBudget)
                    .font(WSFont.subheading(16))
                    .foregroundStyle(Color.wsNavy)
                
                Spacer()
                
                Text(viewModel.budgetText)
                    .font(WSFont.display(24))
                    .foregroundStyle(Color.wsNavy)
            }
            
            Slider(value: $viewModel.budget, in: 25...1000, step: 25)
                .tint(Color.wsNavy)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.budgetPresets, id: \.self) { preset in
                        Button(action: {
                            withAnimation(WSAnimation.spring) {
                                viewModel.budget = preset
                            }
                        }) {
                            Text(preset >= 1000 ? "$1K" : "$\(Int(preset))")
                                .font(WSFont.caption(13))
                                .fontWeight(viewModel.budget == preset ? .bold : .medium)
                                .foregroundStyle(viewModel.budget == preset ? .white : Color.wsNavy)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 9)
                                .background {
                                    if viewModel.budget == preset {
                                        Color.wsNavy
                                    } else {
                                        Color.wsControlFill
                                    }
                                }
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(20)
        .wsCard()
        .padding(.horizontal, 16)
    }
    
    var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppStrings.SmartRegistry.selectCategories)
                .font(WSFont.subheading(16))
                .foregroundStyle(Color.wsNavy)
            
            FlowLayout(spacing: 8) {
                ForEach(viewModel.availableCategories, id: \.self) { category in
                    categoryChip(category)
                }
            }
        }
        .padding(20)
        .wsCard()
        .padding(.horizontal, 16)
    }
    
    func categoryChip(_ category: String) -> some View {
        let isSelected = viewModel.isCategorySelected(category)
        
        return Button(action: {
            withAnimation(WSAnimation.quickSpring) {
                viewModel.toggleCategory(category)
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                Text(category)
                    .font(WSFont.body(13))
            }
            .foregroundStyle(isSelected ? .white : Color.wsNavy)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    WSGradient.button
                } else {
                    Color.wsControlFill
                }
            }
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
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
                    .font(WSFont.subheading(16))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .wsPrimaryButtonBackground()
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(viewModel.isGenerating)
        .opacity(viewModel.isGenerating ? 0.6 : 1)
        .padding(.horizontal, 16)
    }
    
    var generatingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(Color.wsNavy)
                .scaleEffect(1.2)
            
            Text(AppStrings.SmartRegistry.generatingBundles)
                .font(WSFont.body(14))
                .foregroundStyle(Color.wsTextSecondary)
            
            VStack(spacing: 16) {
                ForEach(0..<2, id: \.self) { _ in
                    ShimmerView()
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 16)
    }
    
    var noBundlesView: some View {
        WSEmptyState(
            title: "No Bundles Found",
            systemImage: "sparkles.rectangle.stack",
            message: AppStrings.SmartRegistry.noBundlesMessage
        )
        .padding(.vertical, 40)
    }
    
    var bundlesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Curated Bundles")
                    .font(WSFont.heading(20))
                    .foregroundStyle(Color.wsNavy)
                
                Spacer()
                
                Text("\(viewModel.giftBundles.count) options")
                    .font(WSFont.caption(12))
                    .foregroundStyle(Color.wsTextSecondary)
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
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "gift.fill")
                        .font(.caption)
                        .foregroundStyle(Color.wsAccent)
                    
                    Text(bundle.themeName)
                        .font(WSFont.subheading(17))
                        .foregroundStyle(Color.white)
                    
                    Spacer()
                    
                    Text(bundle.totalPrice, format: .currency(code: "USD"))
                        .font(WSFont.display(20))
                        .foregroundStyle(Color.white)
                }
                
                Text(bundle.themeDescription)
                    .font(WSFont.body(13))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .lineLimit(2)
            }
            .padding(20)
            .background(WSGradient.button)
            
            // Products in bundle
            VStack(spacing: 0) {
                ForEach(bundle.products) { product in
                    bundleProductRow(product, bundle: bundle)
                    
                    if product.id != bundle.products.last?.id {
                        Divider()
                            .overlay(Color.wsNavy.opacity(0.06))
                            .padding(.horizontal, 20)
                    }
                }
            }
            .background(Color.white)
            
            // Status bar
            HStack(spacing: 6) {
                let isWithin = bundle.totalPrice <= viewModel.budget
                Image(systemName: isWithin ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.caption)
                
                if isWithin {
                    Text("Within budget — $\(String(format: "%.2f", viewModel.budget - bundle.totalPrice)) remaining")
                } else {
                    Text("$\(String(format: "%.2f", bundle.totalPrice - viewModel.budget)) over budget")
                }
            }
            .font(WSFont.caption(12))
            .foregroundStyle(bundle.totalPrice <= viewModel.budget ? Color.wsSuccess : .orange)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.wsBackground)
            
            // Add Bundle Row
            HStack(spacing: 0) {
                // Left: item count chip
                HStack(spacing: 5) {
                    Image(systemName: "square.stack.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text("\(bundle.products.count) item\(bundle.products.count == 1 ? "" : "s")")
                        .font(WSFont.caption(12))
                        .fontWeight(.medium)
                }
                .foregroundStyle(Color.wsTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                Spacer()

                // Right: compact add button
                Button(action: {
                    viewModel.addBundleToRegistry(bundle)
                    addedBundleName = bundle.themeName
                    withAnimation(WSAnimation.spring) {
                        showAddedConfirmation = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { showAddedConfirmation = false }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Add to Registry")
                            .font(WSFont.caption(13))
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(WSGradient.button)
                    .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .wsCard()
        .padding(.horizontal, 16)
    }
    
    func bundleProductRow(_ product: ProductItem, bundle: GiftBundleDisplay) -> some View {
        HStack(spacing: 14) {
            CustomAsyncImage(url: product.imageURL)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.wsNavy.opacity(0.08), lineWidth: 1))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(WSFont.body(13))
                    .foregroundStyle(Color.wsNavy)
                    .lineLimit(2)
                
                if let price = product.price {
                    Text(price, format: .currency(code: "USD"))
                        .font(WSFont.price(14))
                        .foregroundStyle(Color.wsAccent)
                }
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(WSAnimation.quickSpring) {
                    viewModel.removeBundleItem(product, from: bundle)
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.wsMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    var confirmationOverlay: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.wsSuccess.opacity(0.2)).frame(width: 32, height: 32)
                    Image(systemName: "checkmark").font(.system(size: 14, weight: .bold)).foregroundStyle(Color.wsSuccess)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Added to Registry")
                        .font(WSFont.subheading(15))
                        .foregroundStyle(Color.wsNavy)
                    Text("\"\(addedBundleName)\" bundle saved")
                        .font(WSFont.caption(12))
                        .foregroundStyle(Color.wsTextSecondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(WSCardBackground(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.15), radius: 20, y: 10)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - Flow Layout
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
