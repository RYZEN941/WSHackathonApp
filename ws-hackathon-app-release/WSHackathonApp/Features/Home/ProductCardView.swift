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

            HStack(alignment: .top) {
                WSWishlistHeartButton(isActive: isWishlisted) {
                    withAnimation(WSAnimation.spring) {
                        wishlistRepository.toggle(product)
                    }
                }

                Spacer()

                HStack(spacing: 6) {
                    if inRegistry {
                        registryBadge
                            .transition(.asymmetric(
                                insertion: .wsBadgeInsert,
                                removal: .opacity
                            ))
                    }
                    registryButton
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

    private var registryBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "gift.fill")
                .font(.system(size: 10, weight: .semibold))
            Text("\(registryQuantity)")
                .font(WSFont.caption(11))
                .contentTransition(.numericText())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(WSGradient.button)
        .clipShape(Capsule(style: .continuous))
    }

    private var registryButton: some View {
        Button(action: inRegistry ? onRemoveFromRegistry : onAddToRegistry) {
            Image(systemName: inRegistry ? "gift.fill" : "gift")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(inRegistry ? .white : Color.wsCharcoal)
                .frame(width: 34, height: 34)
                .background {
                    if inRegistry {
                        WSGradient.button
                    } else {
                        Color.wsControlFill
                    }
                }
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(Color.wsNavy.opacity(inRegistry ? 0 : 0.12), lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
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

            HStack(alignment: .center, spacing: 6) {
                if let price = product.price {
                    Text(price, format: .currency(code: "USD"))
                        .font(WSFont.price(15))
                        .foregroundStyle(Color.wsNavy)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 4)

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
