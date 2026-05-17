import SwiftUI

struct RecipeView: View {
    @StateObject private var viewModel: RecipeViewModel
    @EnvironmentObject var registryRepository: RegistryRepository
    @EnvironmentObject var wishlistRepository: WishlistRepository
    
    @State private var selectedProductForRegistry: ProductItem?
    @State private var showRegistrySelection = false
    
    init(recipe: Recipe) {
        _viewModel = StateObject(wrappedValue: RecipeViewModel(recipe: recipe))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero Image
                if let url = viewModel.recipe.imageUrl {
                    CustomAsyncImage(url: url)
                        .frame(height: 300)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.wsSurface)
                        .frame(height: 300)
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.recipe.title)
                            .font(WSFont.display(32))
                            .foregroundStyle(Color.wsNavy)
                        
                        Text(viewModel.recipe.subtitle)
                            .font(WSFont.heading(18))
                            .foregroundStyle(Color.wsAccent)
                        
                        Text(viewModel.recipe.description)
                            .font(WSFont.body(16))
                            .foregroundStyle(Color.wsTextSecondary)
                            .padding(.top, 4)
                        
                        HStack(spacing: 16) {
                            Label(viewModel.recipe.prepTime, systemImage: "clock")
                            Label(viewModel.recipe.cookTime, systemImage: "flame")
                            Label("\(viewModel.recipe.servings) servings", systemImage: "person.2")
                        }
                        .font(WSFont.caption(14))
                        .foregroundStyle(Color.wsTextSecondary)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    
                    // Recipe-to-Registry AI Recommendation
                    if viewModel.isAnalyzing {
                        loadingRecommendationView
                    } else if let recommendation = viewModel.recommendation {
                        recommendationView(recommendation)
                    }
                    
                    // Ingredients
                    WSSectionHeader(title: "Ingredients")
                        .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.recipe.ingredients, id: \.self) { ingredient in
                            HStack(alignment: .top) {
                                Circle()
                                    .fill(Color.wsAccent)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)
                                Text(ingredient)
                                    .font(WSFont.body(15))
                                    .foregroundStyle(Color.wsText)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Instructions
                    WSSectionHeader(title: "Instructions")
                        .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(Array(viewModel.recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 16) {
                                Text("\(index + 1)")
                                    .font(WSFont.subheading(16))
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(WSGradient.button)
                                    .clipShape(Circle())
                                
                                Text(instruction)
                                    .font(WSFont.body(15))
                                    .foregroundStyle(Color.wsText)
                                    .lineSpacing(4)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
        }
        .background(Color.wsBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.analyzeRecipe()
            }
        }
        .sheet(isPresented: $showRegistrySelection) {
            registrySelectionSheet
        }
    }
    
    // MARK: - AI Recommendation View
    
    private var loadingRecommendationView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(Color.wsAccent)
            Text("Analyzing recipe for required equipment...")
                .font(WSFont.body(14))
                .foregroundStyle(Color.wsTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.wsSurface)
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
    
    private func recommendationView(_ recommendation: RecipeRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.wsAccent)
                Text("Missing equipment?")
                    .font(WSFont.heading(18))
                    .foregroundStyle(Color.wsNavy)
            }
            
            Text(recommendation.detectedMessage)
                .font(WSFont.body(14))
                .foregroundStyle(Color.wsTextSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(recommendation.products) { product in
                        RecipeProductCard(
                            product: product,
                            isWishlisted: wishlistRepository.contains(productId: product.id),
                            onWishlistToggle: { wishlistRepository.toggle(product) },
                            onAddToRegistry: {
                                if registryRepository.registries.count > 1 {
                                    selectedProductForRegistry = product
                                    showRegistrySelection = true
                                } else {
                                    registryRepository.addProduct(product, to: nil)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(WSGradient.cardStroke, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Multi-Registry Selection Sheet
    
    private var registrySelectionSheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add to Registry")
                .font(WSFont.display(24))
                .foregroundStyle(Color.wsNavy)
                .padding(.top, 10)
            
            Text("Select which registry you'd like to add this item to.")
                .font(WSFont.body(14))
                .foregroundStyle(Color.wsTextSecondary)
            
            VStack(spacing: 12) {
                ForEach(registryRepository.registries) { registry in
                    Button {
                        if let product = selectedProductForRegistry {
                            withAnimation(WSAnimation.spring) {
                                registryRepository.addProduct(product, to: registry.id)
                            }
                        }
                        showRegistrySelection = false
                        selectedProductForRegistry = nil
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(registry.displayName)
                                    .font(WSFont.subheading(16))
                                    .foregroundStyle(Color.wsNavy)
                                Text(registry.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(WSFont.caption(12))
                                    .foregroundStyle(Color.wsTextSecondary)
                            }
                            Spacer()
                            Image(systemName: "plus.circle")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.wsAccent)
                        }
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(WSGradient.cardStroke, lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            
            Spacer()
        }
        .padding(24)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Recipe Product Card

private struct RecipeProductCard: View {
    let product: ProductItem
    let isWishlisted: Bool
    let onWishlistToggle: () -> Void
    let onAddToRegistry: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                CustomAsyncImage(url: product.imageURL)
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                WSWishlistHeartButton(isActive: isWishlisted, action: onWishlistToggle)
                    .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(product.title)
                    .font(WSFont.body(13))
                    .foregroundStyle(Color.wsNavy)
                    .lineLimit(2)
                    .frame(minHeight: 36, alignment: .topLeading)
                
                if let price = product.price {
                    Text(price, format: .currency(code: "USD"))
                        .font(WSFont.price(14))
                        .foregroundStyle(Color.wsAccent)
                }
            }
            .padding(.horizontal, 4)
            
            Button(action: onAddToRegistry) {
                HStack(spacing: 6) {
                    Image(systemName: "gift")
                    Text("Add to Registry")
                }
                .font(WSFont.subheading(13))
                .foregroundStyle(Color.wsCharcoal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.wsControlFill)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, 4)
        }
        .padding(10)
        .frame(width: 170)
        .wsCard(cornerRadius: 14)
    }
}
