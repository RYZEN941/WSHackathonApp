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
                        if viewModel.searchText.isEmpty {
                            heroBanner
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
                    wishlistToolbarButton
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
                .overlay(Color.black.opacity(0.05)) // Subtle overlay to ensure text readability on all product images
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
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topLeading) {
                    CustomAsyncImage(url: product.imageURL)
                        .frame(width: 186, height: 190)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    WSWishlistHeartButton(isActive: isWishlisted) {
                        withAnimation(WSAnimation.spring) {
                            wishlistRepository.toggle(product)
                        }
                    }
                    .padding(8)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(product.title)
                        .font(WSFont.body(13))
                        .foregroundStyle(Color.wsNavy)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(minHeight: 36, alignment: .topLeading)

                    if let price = product.price {
                        Text(price, format: .currency(code: "USD"))
                            .font(WSFont.price(15))
                            .foregroundStyle(Color.wsAccent)
                    }
                }
                .padding(.horizontal, 6)
            }
            .padding(12)
            .frame(width: 210, alignment: .leading)
            .wsCard(cornerRadius: 14)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
