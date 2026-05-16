//
//  WishlistView.swift
//  WSHackathonApp
//

import SwiftUI

struct WishlistView: View {

    @EnvironmentObject private var wishlistRepository: WishlistRepository
    @EnvironmentObject private var cartRepository: CartRepository
    @EnvironmentObject private var registryRepository: RegistryRepository
    @EnvironmentObject private var tabBarVM: WSTabBarViewModel

    @StateObject private var homeViewModel = HomeViewModel()
    @State private var selectedProduct: ProductItem?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            if wishlistRepository.items.isEmpty {
                WSEmptyState(
                    title: AppStrings.Wishlist.emptyTitle,
                    systemImage: "heart",
                    message: AppStrings.Wishlist.emptyMessage
                )
                .padding(.top, 60)
            } else {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(wishlistRepository.items) { product in
                        ProductCardView(
                            product: product,
                            quantity: homeViewModel.quantity(for: product),
                            registryQuantity: homeViewModel.registryQuantity(for: product),
                            onSelect: { selectedProduct = product },
                            onAdd: { homeViewModel.addToCart(product) },
                            onRemove: { homeViewModel.removeFromCart(product) },
                            onAddToRegistry: {
                                if homeViewModel.canAddToRegistry(product) {
                                    homeViewModel.addToRegistry(product)
                                } else {
                                    tabBarVM.selectTab(.registry)
                                }
                            },
                            onRemoveFromRegistry: { homeViewModel.removeFromRegistry(product) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .wsAppBackground()
        .navigationTitle(AppStrings.Wishlist.title)
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $selectedProduct) { product in
            ProductDetailView(product: product)
        }
        .onAppear {
            homeViewModel.bind(
                cartRepository: cartRepository,
                registryRepository: registryRepository
            )
        }
    }
}
