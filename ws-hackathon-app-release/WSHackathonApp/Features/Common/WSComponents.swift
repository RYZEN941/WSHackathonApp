//
//  WSComponents.swift
//  WSHackathonApp
//

import SwiftUI

// MARK: - Section Header

struct WSSectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(WSGradient.shimmerBar)
                    .frame(width: 3, height: 22)
                    .padding(.top, 2)

                Text(title)
                    .font(WSFont.heading(18))
                    .foregroundStyle(Color.wsNavy)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .minimumScaleFactor(0.9)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let subtitle {
                Text(subtitle)
                    .font(WSFont.body(13))
                    .foregroundStyle(Color.wsTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 13)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Wishlist heart

struct WSWishlistHeartButton: View {
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isActive ? "heart.fill" : "heart")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isActive ? Color.wsAccent : Color.wsNavy)
                .frame(width: 34, height: 34)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(
                            isActive ? Color.wsAccent.opacity(0.5) : Color.wsNavy.opacity(0.12),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(isActive ? "Remove from wishlist" : "Add to wishlist")
        .animation(WSAnimation.quickSpring, value: isActive)
    }
}

// MARK: - Quantity Stepper

struct WSQuantityStepper: View {
    let quantity: Int
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var decrementIcon: String { quantity <= 1 ? "trash" : "minus" }
    var decrementTint: Color { quantity <= 1 ? .red : .wsAction }

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onDecrement) {
                Image(systemName: decrementIcon)
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 28, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(decrementTint)

            Text("\(quantity)")
                .font(WSFont.subheading(13))
                .foregroundStyle(Color.wsNavy)
                .frame(minWidth: 20)
                .multilineTextAlignment(.center)
                .contentTransition(.numericText())
                .animation(WSAnimation.quickSpring, value: quantity)

            Button(action: onIncrement) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 28, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.wsAction)
        }
        .background(Color.wsControlFill)
        .clipShape(Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.wsNavy.opacity(0.12), lineWidth: 1)
        )
        .fixedSize()
    }
}

// MARK: - Animated swap (plus ↔ stepper)

struct WSAnimatedControlSlot<Expanded: View, Collapsed: View>: View {
    let isExpanded: Bool
    @ViewBuilder var expanded: () -> Expanded
    @ViewBuilder var collapsed: () -> Collapsed

    var body: some View {
        ZStack(alignment: .trailing) {
            if isExpanded {
                expanded()
                    .transition(.asymmetric(
                        insertion: .wsControlInsert,
                        removal: .wsControlRemove
                    ))
            } else {
                collapsed()
                    .transition(.asymmetric(
                        insertion: .wsControlInsert,
                        removal: .wsControlRemove
                    ))
            }
        }
        .frame(height: 36)
        .animation(WSAnimation.spring, value: isExpanded)
    }
}

// MARK: - Primary Button

struct WSPrimaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(WSFont.subheading(16))
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .wsPrimaryButtonBackground()
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Checkout Bar

struct WSCheckoutBar: View {
    let totalLabel: String
    let totalValue: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(totalLabel)
                    .font(WSFont.subheading(17))
                    .foregroundStyle(Color.wsTextSecondary)
                Spacer()
                Text(totalValue)
                    .font(WSFont.display(26))
                    .foregroundStyle(Color.wsNavy)
            }

            WSPrimaryButton(title: buttonTitle, icon: "bag.fill", action: action)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

// MARK: - Empty State

struct WSEmptyState: View {
    let title: String
    let systemImage: String
    let message: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.wsSurface, Color.wsCard],
                            center: .center,
                            startRadius: 8,
                            endRadius: 56
                        )
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(WSGradient.cardStroke, lineWidth: 1)
                    )
                    .frame(width: 100, height: 100)
                Image(systemName: systemImage)
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Color.wsAction)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(WSFont.heading(22))
                    .foregroundStyle(Color.wsNavy)
                Text(message)
                    .font(WSFont.body(15))
                    .foregroundStyle(Color.wsTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let buttonTitle, let action {
                WSPrimaryButton(title: buttonTitle, action: action)
                    .padding(.horizontal, 48)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Registry Hero Card

struct WSRegistryHeroCard: View {
    let onCreate: () -> Void

    private let cardHeight: CGFloat = 200

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Bounded container — prevents ScrollView from expanding to image pixel width
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.wsSurface)
                .overlay {
                    Image(AppImages.Registry.header)
                        .resizable()
                        .scaledToFill()
                }
                .frame(height: cardHeight)
                .clipped()

            WSGradient.heroOverlay
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                Text("CREATE YOUR REGISTRY")
                    .font(WSFont.caption(10))
                    .tracking(2)
                    .foregroundStyle(.black.opacity(0.8))

                Text("Celebrate life's milestones with us.")
                    .font(WSFont.display(24))
                    .foregroundStyle(.black)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)

                Button(action: onCreate) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Get Started")
                            .font(WSFont.subheading(14))
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .wsLightButtonBackground(cornerRadius: 10)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(18)
        }
        .frame(height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(WSGradient.cardStroke, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 6)
    }
}

