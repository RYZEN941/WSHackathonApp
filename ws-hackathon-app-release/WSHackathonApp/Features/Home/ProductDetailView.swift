//
//  ProductDetailView.swift
//  WSHackathonApp
//

import SwiftUI

struct ProductDetailView: View {

    @StateObject private var viewModel: ProductDetailViewModel
    @EnvironmentObject private var cartRepository: CartRepository
    @EnvironmentObject private var registryRepository: RegistryRepository
    @EnvironmentObject private var tabBarVM: WSTabBarViewModel
    @EnvironmentObject private var wishlistRepository: WishlistRepository
    @Environment(\.dismiss) private var dismiss
    
    @State private var showRegistrySelection = false
    @State private var showARView = false

    private var isWishlisted: Bool {
        wishlistRepository.contains(productId: viewModel.product.id)
    }

    init(product: ProductItem) {
        _viewModel = StateObject(wrappedValue: ProductDetailViewModel(product: product))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroImage
                    detailPanel
                }
                .padding(.bottom, 120)
            }

            actionBar
        }
        .wsAppBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        withAnimation(WSAnimation.spring) {
                            wishlistRepository.toggle(viewModel.product)
                        }
                    } label: {
                        Image(systemName: isWishlisted ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isWishlisted ? Color.wsAccent : Color.wsCharcoal)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel(isWishlisted ? "Remove from wishlist" : "Add to wishlist")

                    shareButton
                }
            }
        }
        .onAppear {
            viewModel.bind(
                cartRepository: cartRepository,
                registryRepository: registryRepository
            )
            Task {
                await viewModel.fetchSimilarProducts()
            }
        }
        .animation(WSAnimation.spring, value: viewModel.inCart)
        .animation(WSAnimation.spring, value: viewModel.inRegistry)
        .sheet(isPresented: $showRegistrySelection) {
            registrySelectionSheet
        }
        .fullScreenCover(isPresented: $showARView) {
            if let modelName = viewModel.product.usdzModelName {
                ARModelView(modelName: modelName, productTitle: viewModel.product.title)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Hero

    private var heroImage: some View {
        ZStack(alignment: .bottom) {
            Color.wsSurface
                .frame(height: 380)
                .overlay {
                    CustomAsyncImage(url: viewModel.product.imageURL)
                }
                .clipped()

            WSGradient.heroOverlay
                .frame(height: 380)

            HStack(alignment: .top) {
                WSWishlistHeartButton(isActive: isWishlisted) {
                    withAnimation(WSAnimation.spring) {
                        wishlistRepository.toggle(viewModel.product)
                    }
                }
                .padding(.leading, 20)
                .padding(.top, 12)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                statusBadge(
                    icon: viewModel.product.isInStock ? "checkmark.circle.fill" : "clock.fill",
                    text: viewModel.product.availabilityLabel,
                    tint: viewModel.product.isInStock ? Color.wsSuccess : Color.wsAccent
                )
                if viewModel.product.freeShip == true {
                    statusBadge(icon: "shippingbox.fill", text: "Free Shipping", tint: Color.wsAction)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 44)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 380)
    }

    private func statusBadge(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(WSFont.caption(11))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.92))
        .clipShape(Capsule(style: .continuous))
    }

    // MARK: - Detail panel

    private var detailPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                accentRule

                Text(viewModel.product.brand?.uppercased() ?? "WILLIAMS SONOMA")
                    .font(WSFont.caption(11))
                    .tracking(2.5)
                    .foregroundStyle(Color.wsAccent)

                Text(viewModel.product.title)
                    .font(WSFont.display(28))
                    .foregroundStyle(Color.wsNavy)
                    .fixedSize(horizontal: false, vertical: true)

                if let price = viewModel.product.price {
                    Text(price, format: .currency(code: "USD"))
                        .font(WSFont.display(32))
                        .foregroundStyle(Color.wsNavy)
                }

                Text(viewModel.product.editorialDescription)
                    .font(WSFont.body(15))
                    .foregroundStyle(Color.wsTextSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 24)

            Divider()
                .overlay(Color.wsNavy.opacity(0.08))
                .padding(.horizontal, 24)

            VStack(spacing: 0) {
                if let material = viewModel.product.material, !material.isEmpty {
                    detailRow(label: "Material", value: material.capitalized)
                }
                detailRow(label: "Availability", value: viewModel.product.availabilityLabel)
                detailRow(label: "Item", value: viewModel.product.id, isLast: true)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)

            if viewModel.product.usdzModelName != nil {
                arVisualizationSection
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
            }

            registrySection
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 28)
                
            if !viewModel.similarProducts.isEmpty {
                similarItemsSection
            }
        }
        .background {
            WSCardBackground(cornerRadius: 28)
        }
        .offset(y: -32)
    }

    private var accentRule: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(WSGradient.button)
                .frame(width: 36, height: 3)
            Rectangle()
                .fill(WSGradient.accent)
                .frame(width: 12, height: 3)
        }
        .clipShape(Capsule(style: .continuous))
    }

    private func detailRow(label: String, value: String, isLast: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Text(label)
                    .font(WSFont.body(14))
                    .foregroundStyle(Color.wsTextSecondary)
                Spacer(minLength: 16)
                Text(value)
                    .font(WSFont.subheading(14))
                    .foregroundStyle(Color.wsNavy)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, 14)

            if !isLast {
                Divider()
                    .overlay(Color.wsNavy.opacity(0.06))
            }
        }
    }

    private var registrySection: some View {
        Button {
            if viewModel.inRegistry {
                // If in multiple, maybe show list to manage? For now toggle/remove from all
                viewModel.removeFromRegistry()
            } else if viewModel.canAddToRegistry {
                if viewModel.registries.count > 1 {
                    showRegistrySelection = true
                } else {
                    viewModel.addToRegistry()
                }
            } else {
                dismiss()
                tabBarVM.selectTab(.registry)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: viewModel.inRegistry ? "gift.fill" : "gift")
                    .font(.system(size: 16, weight: .semibold))
                Text(registryButtonTitle)
                    .font(WSFont.subheading(15))
                Spacer()
                if viewModel.inRegistry {
                    Text("\(viewModel.registryQuantity) in registry")
                        .font(WSFont.caption(12))
                        .foregroundStyle(Color.wsTextSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.wsMuted)
            }
            .foregroundStyle(Color.wsAction)
            .padding(16)
            .background(Color.wsControlFill.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(WSGradient.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var registryButtonTitle: String {
        if viewModel.inRegistry { return "Added to Registry" }
        if viewModel.canAddToRegistry { return "Add to Registry" }
        return "Create a Registry"
    }

    // MARK: - Bottom bar

    private var actionBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 14) {
                if viewModel.inCart {
                    WSQuantityStepper(
                        quantity: viewModel.cartQuantity,
                        onDecrement: viewModel.removeFromCart,
                        onIncrement: viewModel.addToCart
                    )
                }

                Button {
                    if viewModel.inCart {
                        tabBarVM.selectTab(.cart)
                    } else {
                        viewModel.addToCart()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.inCart ? "bag.fill" : "bag.badge.plus")
                        Text(viewModel.inCart ? "View Cart" : "Add to Bag")
                            .font(WSFont.subheading(16))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .wsPrimaryButtonBackground()
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 10)
        }
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var shareButton: some View {
        ShareLink(item: viewModel.product.title) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.wsNavy)
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
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
                ForEach(viewModel.registries) { registry in
                    Button {
                        viewModel.addToRegistry(registry.id)
                        showRegistrySelection = false
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
                        .background(Color.wsControlFill)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
    
    private var similarItemsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(WSGradient.accent)
                        .font(.system(size: 14, weight: .semibold))
                    Text("You Might Also Like")
                        .font(WSFont.subheading(16))
                        .foregroundStyle(Color.wsNavy)
                }
                Text("AI-curated matching culinary companion recommendations")
                    .font(WSFont.caption(12))
                    .foregroundStyle(Color.wsTextSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.similarProducts) { similarProduct in
                        NavigationLink(destination: ProductDetailView(product: similarProduct)) {
                            SimilarProductCard(product: similarProduct)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    private var arVisualizationSection: some View {
        Button {
            showARView = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(WSGradient.button)
                        .frame(width: 46, height: 46)
                    Image(systemName: "arkit")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Visualize in AR")
                        .font(WSFont.subheading(16))
                        .foregroundStyle(Color.wsNavy)
                        .fontWeight(.bold)
                    Text("See this item in 3D inside your room")
                        .font(WSFont.caption(12))
                        .foregroundStyle(Color.wsTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right.and.arrow.down.left.rectangle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.wsAccent)
                    .padding(8)
                    .background(Color.wsControlFill)
                    .clipShape(Circle())
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.wsBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.wsAccent.opacity(0.4), Color.wsNavy.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.wsNavy.opacity(0.04), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct SimilarProductCard: View {
    let product: ProductItem
    @EnvironmentObject private var cartRepository: CartRepository
    
    private var isInCart: Bool {
        cartRepository.items.contains(where: { $0.id == product.id })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                CustomAsyncImage(url: product.imageURL)
                    .frame(width: 140, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                // Swiggy-style Add button
                Button {
                    withAnimation(WSAnimation.spring) {
                        if isInCart {
                            cartRepository.remove(productId: product.id)
                        } else {
                            cartRepository.add(product: product)
                        }
                    }
                } label: {
                    Image(systemName: isInCart ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(isInCart ? Color.wsSuccess : Color.wsAction)
                        .background(Circle().fill(.white))
                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                }
                .padding(6)
            }
            .frame(width: 140, height: 110)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(WSFont.subheading(13))
                    .foregroundStyle(Color.wsNavy)
                    .lineLimit(2)
                    .frame(height: 36, alignment: .topLeading)
                    .multilineTextAlignment(.leading)
                
                if let price = product.price {
                    Text(price, format: .currency(code: "USD"))
                        .font(WSFont.body(13))
                        .bold()
                        .foregroundStyle(Color.wsAction)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 140)
        .padding(8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.wsNavy.opacity(0.04), radius: 6, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.wsNavy.opacity(0.05), lineWidth: 1)
        )
    }
}
