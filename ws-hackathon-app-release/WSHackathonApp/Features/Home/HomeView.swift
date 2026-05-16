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
        }
    }

    private var wishlistToolbarButton: some View {
        Button {
            showWishlist = true
        } label: {
            Image(systemName: wishlistRepository.count > 0 ? "heart.fill" : "heart")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(wishlistRepository.count > 0 ? Color.red : Color.wsCharcoal)
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
                    Image(AppImages.Registry.header)
                        .resizable()
                        .scaledToFill()
                }
                .frame(height: 220)
                .clipped()

            WSGradient.heroOverlay

            VStack(alignment: .leading, spacing: 10) {
                Text("THE SPRING EDIT")
                    .font(WSFont.caption(10))
                    .tracking(2.5)
                    .foregroundStyle(.white.opacity(0.9))

                Text("Refined Living.")
                    .font(WSFont.display(34))
                    .foregroundStyle(.white)

                Text("Handpicked essentials for the season ahead.")
                    .font(WSFont.body(13))
                    .foregroundStyle(.white.opacity(0.85))

                Button(action: {}) {
                    Text("SHOP NOW")
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
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(WSGradient.cardStroke, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 6)
        .padding(.horizontal, 16)
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
                                    viewModel.addToRegistry(product)
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
                        .frame(width: 152, height: 196)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    WSWishlistHeartButton(isActive: isWishlisted) {
                        withAnimation(WSAnimation.spring) {
                            wishlistRepository.toggle(product)
                        }
                    }
                    .padding(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(product.title)
                        .font(WSFont.body(12))
                        .foregroundStyle(Color.wsNavy)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let price = product.price {
                        Text(price, format: .currency(code: "USD"))
                            .font(WSFont.price(14))
                            .foregroundStyle(Color.wsAccent)
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(10)
            .frame(width: 168, alignment: .leading)
            .wsCard(cornerRadius: 14)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
