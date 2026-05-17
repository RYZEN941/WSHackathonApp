//
//  ProductCardView.swift
//  WSHackathonApp
//

import SwiftUI

struct ProductCardView: View {
    let product: ProductItem
    let quantity: Int
    let registryQuantity: Int
    let onSelect: () -> Void
    let onAdd: () -> Void
    let onRemove: () -> Void
    let onAddToRegistry: () -> Void
    let onRemoveFromRegistry: () -> Void

    @EnvironmentObject private var wishlistRepository: WishlistRepository

    private var inCart: Bool { quantity > 0 }
    private var inRegistry: Bool { registryQuantity > 0 }
    private var isWishlisted: Bool { wishlistRepository.contains(productId: product.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageSection
            infoSection
        }
        .wsCard()
        .animation(WSAnimation.spring, value: inCart)
        .animation(WSAnimation.spring, value: inRegistry)
        .animation(WSAnimation.quickSpring, value: isWishlisted)
    }

    private var imageSection: some View {
        ZStack(alignment: .top) {
            Button(action: onSelect) {
                CustomAsyncImage(url: product.imageURL)
                    .frame(height: 150)
                    .clipped()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("View \(product.title)")

            HStack {
                Spacer()
                WSWishlistHeartButton(isActive: isWishlisted) {
                    withAnimation(WSAnimation.spring) {
                        wishlistRepository.toggle(product)
                    }
                }
            }
            .padding(10)
        }
        .frame(height: 150)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 14,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 14,
                style: .continuous
            )
        )
    }

    private var registryButton: some View {
        Button(action: inRegistry ? onRemoveFromRegistry : onAddToRegistry) {
            HStack(spacing: 5) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 14, weight: .semibold))
                if inRegistry {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .foregroundStyle(inRegistry ? .white : Color.wsCharcoal)
            .padding(.horizontal, inRegistry ? 14 : 10)
            .frame(height: 34)
            .background {
                if inRegistry {
                    WSGradient.button
                } else {
                    Color.wsControlFill
                }
            }
            .clipShape(Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(Color.wsNavy.opacity(inRegistry ? 0 : 0.12), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(WSAnimation.spring, value: inRegistry)
        .accessibilityLabel(inRegistry ? "Remove from registry" : "Add to registry")
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onSelect) {
                Text(product.title)
                    .font(WSFont.body(13))
                    .foregroundStyle(Color.wsNavy)
                    .lineLimit(2)
                    .frame(minHeight: 36, alignment: .topLeading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            // Price
            if let price = product.price {
                Text(price, format: .currency(code: "USD"))
                    .font(WSFont.price(15))
                    .foregroundStyle(Color.wsNavy)
                    .fixedSize(horizontal: true, vertical: false)
            }

            // Bottom row: registry button (left) + cart control (right)
            HStack(alignment: .center) {
                // Registry pill — bottom left
                registryButton

                Spacer()

                // Cart stepper / plus button — right
                WSAnimatedControlSlot(isExpanded: inCart) {
                    WSQuantityStepper(
                        quantity: quantity,
                        onDecrement: onRemove,
                        onIncrement: onAdd
                    )
                } collapsed: {
                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.wsCharcoal)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityLabel("Add to cart")
                }
            }
        }
        .padding(12)
    }
}
