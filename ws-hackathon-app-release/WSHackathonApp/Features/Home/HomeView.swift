//
//  HomeView.swift
//  WSHackathonApp
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var navigationPath = NavigationPath()
    @State private var showWishlist = false
    @EnvironmentObject var cartRepository: CartRepository
    @EnvironmentObject var registryRepository: RegistryRepository
    @EnvironmentObject var wishlistRepository: WishlistRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    
    @State private var selectedProductForRegistry: ProductItem?
    @State private var showRegistrySelection = false
    @State private var showUserSwitcher = false

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    if viewModel.isLoading && viewModel.products.isEmpty {
                        loadingView
                    } else {
                        if viewModel.searchText.isEmpty && viewModel.selectedCategory == nil {
                            trendingRecipesSection
                            curatedSection
                        }
                        
                        allProductsSection
                    }
                }
                .padding(.vertical, 12)
                .padding(.bottom, 24)
            }
            .safeAreaInset(edge: .top) {
                categorySelector
                    .padding(.bottom, 12)
                    .background(Color.wsBackground)
            }
            .wsAppBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("WILLIAMS SONOMA")
                            .font(WSFont.label(10))
                            .tracking(3.5)
                            .foregroundStyle(Color.wsCharcoal)
                        Rectangle()
                            .fill(WSGradient.accent)
                            .frame(width: 24, height: 2)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        wishlistToolbarButton
                        userSwitcherToolbarButton
                    }
                }
            }
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: AppStrings.Home.searchPlaceHolder
            )
            .navigationDestination(for: ProductItem.self) { product in
                ProductDetailView(product: product)
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeView(recipe: recipe)
            }
            .navigationDestination(isPresented: $showWishlist) {
                WishlistView()
            }
            .onAppear {
                Task {
                    viewModel.bind(
                        cartRepository: cartRepository,
                        registryRepository: registryRepository
                    )
                    await viewModel.fetchProducts()
                }
            }
            .sheet(isPresented: $showRegistrySelection) {
                registrySelectionSheet
            }
            .sheet(isPresented: $showUserSwitcher) {
                UserSwitcherSheet(isPresented: $showUserSwitcher)
            }
        }
    }

    private var wishlistToolbarButton: some View {
        Button {
            showWishlist = true
        } label: {
            Image(systemName: wishlistRepository.count > 0 ? "heart.fill" : "heart")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(wishlistRepository.count > 0 ? Color.wsAccent : Color.wsCharcoal)
                .symbolRenderingMode(.hierarchical)
        }
        .badge(wishlistRepository.count)
        .accessibilityLabel("Wishlist, \(wishlistRepository.count) items")
    }
    
    private var userSwitcherToolbarButton: some View {
        Button {
            showUserSwitcher = true
        } label: {
            Image(systemName: "person.circle")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(Color.wsNavy)
        }
    }

    private func switchActiveUser(to user: RegistryRepository.MockUser) {
        withAnimation(WSAnimation.spring) {
            registryRepository.switchUser(to: user)
            cartRepository.switchUser(toUserId: user.id)
            wishlistRepository.switchUser(toUserId: user.id)
        }
    }

    private func openProduct(_ product: ProductItem) {
        navigationPath.append(product)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color.wsNavy)
                .scaleEffect(1.1)
            Text("Curating our collection…")
                .font(WSFont.body(14))
                .foregroundStyle(Color.wsTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private var heroBanner: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.wsSurface)
                .overlay {
                    bannerImage
                        .id(viewModel.selectedCategory ?? "all")
                        .transition(.opacity)
                }
                .frame(height: 220)
                .clipped()
            // Strong scrim layers for guaranteed text readability
            Color.white.opacity(0.45)
            
            LinearGradient(
                colors: [
                    Color.white.opacity(0.95),
                    Color.white.opacity(0.75),
                    Color.white.opacity(0.3),
                    Color.clear
                ],
                startPoint: .bottom,
                endPoint: .top
            )

            VStack(alignment: .leading, spacing: 10) {
                Text(bannerContent.subtitle)
                    .font(WSFont.caption(10))
                    .tracking(2.5)
                    .foregroundStyle(Color.wsCharcoal.opacity(0.8))

                Text(bannerContent.title)
                    .font(WSFont.display(34))
                    .foregroundStyle(Color.wsCharcoal)

                Text(bannerContent.description)
                    .font(WSFont.body(13))
                    .foregroundStyle(Color.wsCharcoal.opacity(0.75))

                Button(action: {}) {
                    Text(bannerContent.buttonTitle)
                        .font(WSFont.label(11))
                        .tracking(2)
                        .foregroundStyle(Color.wsCharcoal)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 11)
                        .wsLightButtonBackground(cornerRadius: 2)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, 4)
            }
            .padding(22)
            .id(viewModel.selectedCategory ?? "Default")
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(WSGradient.cardStroke, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 6)
        .padding(.horizontal, 16)
        .animation(.easeInOut(duration: 0.6), value: viewModel.selectedCategory)
    }

    @ViewBuilder
    private var bannerImage: some View {
        let imageURL: URL? = {
            let products = viewModel.products
            switch viewModel.selectedCategory {
            case "Cookware":
                return products.first(where: { $0.productType?.contains("dutch-oven") ?? false || $0.productType?.contains("skillet") ?? false })?.imageURL
            case "Dining":
                return products.first(where: { $0.productType?.contains("plate") ?? false || $0.productType?.contains("bowl") ?? false })?.imageURL
            case "Coffee & Tea":
                return products.first(where: { $0.productType?.contains("coffee") ?? false || $0.productType?.contains("mug") ?? false })?.imageURL
            case "Kitchen":
                return products.first(where: { $0.productType?.contains("cutting-board") ?? false })?.imageURL
            case "Bar & Glassware":
                return products.first(where: { $0.productType?.contains("glass") ?? false || $0.title.lowercased().contains("martini") })?.imageURL
            case "Food & Pantry":
                return products.first(where: { $0.productType?.contains("oil") ?? false })?.imageURL
            case "Home & Décor":
                return products.first(where: { $0.title.lowercased().contains("lazy") })?.imageURL
            default:
                return nil
            }
        }()
        
        if let imageURL = imageURL {
            CustomAsyncImage(url: imageURL)
                .overlay(Color.black.opacity(0.05))
        } else {
            Image(AppImages.Registry.header)
                .resizable()
                .scaledToFill()
        }
    }

    private var bannerContent: (title: String, subtitle: String, description: String, buttonTitle: String) {
        switch viewModel.selectedCategory {
        case "Cookware":
            return ("Master the Art.", "PRO-GRADE TOOLS", "Performance-driven essentials for the home chef.", "EXPLORE COOKWARE")
        case "Dining":
            return ("Elegant Hosting.", "DINING & ENTERTAINING", "Set the table with timeless porcelain and silver.", "SHOP DINING")
        case "Coffee & Tea":
            return ("The Perfect Brew.", "MORNING RITUALS", "Artisanal machines and curated ceramic mugs.", "SHOP COFFEE")
        case "Kitchen":
            return ("Kitchen Refresh.", "KITCHEN ESSENTIALS", "Organize your space with beautiful, functional tools.", "SHOP KITCHEN")
        case "Bar & Glassware":
            return ("Raise a Glass.", "HOME BAR", "Premium glassware and mixology essentials.", "SHOP BARWARE")
        case "Food & Pantry":
            return ("Gourmet Pantry.", "ARTISANAL FLAVORS", "Elevate your recipes with premium ingredients.", "SHOP PANTRY")
        case "Home & Décor":
            return ("Artful Touches.", "HOME DECOR", "Beautiful accents to complete your living space.", "SHOP DECOR")
        default:
            return ("Refined Living.", "THE SPRING EDIT", "Handpicked essentials for the season ahead.", "SHOP NOW")
        }
    }

    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.categories, id: \.self) { category in
                    let isSelected = (viewModel.selectedCategory == category) || (category == "All" && viewModel.selectedCategory == nil)
                    
                    Button {
                        withAnimation(WSAnimation.quickSpring) {
                            if category == "All" {
                                viewModel.selectedCategory = nil
                            } else {
                                viewModel.selectedCategory = category
                            }
                        }
                    } label: {
                        Text(category)
                            .font(WSFont.label(12))
                            .tracking(1)
                            .foregroundStyle(isSelected ? .white : Color.wsNavy)
                            .padding(.horizontal, 18)
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
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var trendingRecipesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            WSSectionHeader(
                title: "Trending Recipes",
                subtitle: "Culinary inspiration for your registry"
            )
            .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Recipe.allMocks) { recipe in
                        Button {
                            navigationPath.append(recipe)
                        } label: {
                            ZStack(alignment: .bottomLeading) {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.wsSurface)
                                    .overlay {
                                        if let url = recipe.imageUrl {
                                            CustomAsyncImage(url: url)
                                                .scaledToFill()
                                        }
                                    }
                                    .frame(width: 280, height: 180)
                                    .clipped()
                                
                                WSGradient.heroOverlay
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("RECIPE")
                                        .font(WSFont.caption(10))
                                        .tracking(2)
                                        .foregroundStyle(Color.white.opacity(0.9))
                                    
                                    Text(recipe.title)
                                        .font(WSFont.heading(22))
                                        .foregroundStyle(.white)
                                        .lineLimit(2)
                                }
                                .padding(16)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(WSGradient.cardStroke, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .scrollTransition { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1.0 : 0.95)
                                .opacity(phase.isIdentity ? 1.0 : 0.75)
                        }
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 16)
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }

    private var curatedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            WSSectionHeader(
                title: "Curated For You",
                subtitle: "Editor's picks from our latest arrivals"
            )
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.filteredProducts.prefix(6)) { product in
                        CuratedProductCard(product: product) {
                            openProduct(product)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
    }

    private var allProductsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            WSSectionHeader(
                title: viewModel.searchText.isEmpty ? "Our Collection" : "Search Results",
                subtitle: viewModel.searchText.isEmpty
                    ? "\(viewModel.filteredProducts.count) pieces"
                    : "\(viewModel.filteredProducts.count) matches"
            )
            .padding(.horizontal, 16)

            if viewModel.filteredProducts.isEmpty {
                WSEmptyState(
                    title: "No Results",
                    systemImage: "magnifyingglass",
                    message: "Try a different search term to discover our collection."
                )
                .padding(.top, 40)
            } else {
                LazyVGrid(columns: gridColumns, spacing: 20) {
                    ForEach(viewModel.filteredProducts) { product in
                        ProductCardView(
                            product: product,
                            quantity: viewModel.quantity(for: product),
                            registryQuantity: viewModel.registryQuantity(for: product),
                            onSelect: { openProduct(product) },
                            onAdd: { viewModel.addToCart(product) },
                            onRemove: { viewModel.removeFromCart(product) },
                            onAddToRegistry: {
                                if viewModel.canAddToRegistry(product) {
                                    if registryRepository.registries.count > 1 {
                                        selectedProductForRegistry = product
                                        showRegistrySelection = true
                                    } else {
                                        viewModel.addToRegistry(product)
                                    }
                                } else {
                                    tabBarVM.selectTab(.registry)
                                }
                            },
                            onRemoveFromRegistry: { viewModel.removeFromRegistry(product) }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

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
                            viewModel.addToRegistry(product, to: registry.id)
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
                        .shadow(color: Color.black.opacity(0.03), radius: 5, y: 2)
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

// MARK: - Curated Card

private struct CuratedProductCard: View {
    let product: ProductItem
    let onSelect: () -> Void

    @EnvironmentObject private var wishlistRepository: WishlistRepository

    private var isWishlisted: Bool { wishlistRepository.contains(productId: product.id) }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                // Image Section
                ZStack(alignment: .topTrailing) {
                    CustomAsyncImage(url: product.imageURL)
                        .frame(height: 150)
                        .clipped()
                    
                    WSWishlistHeartButton(isActive: isWishlisted) {
                        withAnimation(WSAnimation.spring) {
                            wishlistRepository.toggle(product)
                        }
                    }
                    .padding(10)
                }
                .frame(height: 150)
                .frame(width: 170)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 14,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 14,
                        style: .continuous
                    )
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text(product.title)
                        .font(WSFont.body(13))
                        .foregroundStyle(Color.wsNavy)
                        .lineLimit(2)
                        .frame(minHeight: 36, alignment: .topLeading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let price = product.price {
                        Text(price, format: .currency(code: "USD"))
                            .font(WSFont.price(15))
                            .foregroundStyle(Color.wsAccent)
                    }
                }
                .padding(12)
                .frame(width: 170)
            }
            .wsCard()
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct UserSwitcherSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var cartRepository: CartRepository
    @EnvironmentObject var registryRepository: RegistryRepository
    @EnvironmentObject var wishlistRepository: WishlistRepository
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Switch Active Profile")
                    .font(WSFont.heading(24))
                    .foregroundStyle(Color.wsNavy)
                    .padding(.top, 16)
                
                VStack(spacing: 16) {
                    userButton(for: RegistryRepository.mockUser1)
                    userButton(for: RegistryRepository.mockUser2)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .background(Color.wsBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .font(WSFont.body(16))
                    .foregroundStyle(Color.wsNavy)
                }
            }
        }
        .presentationDetents([.fraction(0.4)])
        .presentationDragIndicator(.visible)
    }
    
    private func userButton(for user: RegistryRepository.MockUser) -> some View {
        let isSelected = registryRepository.currentUser.id == user.id
        
        return Button {
            withAnimation(WSAnimation.spring) {
                registryRepository.switchUser(to: user)
                cartRepository.switchUser(toUserId: user.id)
                wishlistRepository.switchUser(toUserId: user.id)
                isPresented = false
            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: isSelected ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.wsAccent : Color.wsMuted)
                
                Text(user.name)
                    .font(WSFont.subheading(18))
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundStyle(isSelected ? Color.wsNavy : Color.wsTextSecondary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.wsAccent)
                }
            }
            .padding()
            .background(isSelected ? Color.wsAccent.opacity(0.1) : Color.wsSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Color.wsAccent.opacity(0.5) : Color.wsBorder, lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
