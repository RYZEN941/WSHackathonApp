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
                            .foregroundStyle(isWishlisted ? .red : Color.wsCharcoal)
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
        }
        .animation(WSAnimation.spring, value: viewModel.inCart)
        .animation(WSAnimation.spring, value: viewModel.inRegistry)
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

            registrySection
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 28)
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
                viewModel.removeFromRegistry()
            } else if viewModel.canAddToRegistry {
                viewModel.addToRegistry()
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
                        Text(viewModel.inCart ? "View Bag" : "Add to Bag")
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
}
