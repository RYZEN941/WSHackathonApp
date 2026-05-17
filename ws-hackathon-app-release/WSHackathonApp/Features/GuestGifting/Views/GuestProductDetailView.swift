//
//  GuestProductDetailView.swift
//  WSHackathonApp
//

import SwiftUI

struct GuestProductDetailView: View {
    let giftItem: GiftabilityItem
    let registry: Registry

    @EnvironmentObject var registryRepo: RegistryRepository
    @State private var isGroupContribute = false
    @State private var contributionAmount: Double = 0
    @State private var contributionText: String = ""
    @State private var giftMessage: String = ""
    @State private var showGiftMessage = false
    @State private var navigateToCheckout = false

    var meaningfulText: String {
        let title = giftItem.item.title.lowercased()
        if title.contains("knife") || title.contains("cutting") || title.contains("board") {
            return "The perfect foundation for a home chef — this piece will be at the center of every meal they share together."
        } else if title.contains("dutch oven") || title.contains("cocotte") || title.contains("skillet") {
            return "Passed down through generations, premium cookware becomes a family heirloom. Give them a piece that will last a lifetime."
        } else if title.contains("coffee") || title.contains("espresso") {
            return "Every morning ritual begins here. Help them start each day together with the perfect cup."
        } else if title.contains("glass") || title.contains("martini") || title.contains("wine") {
            return "For the celebrations, toasts, and quiet evenings to come — beautiful glassware elevates every occasion."
        } else {
            return "A thoughtful, practical gift that will be used and appreciated every single day in their new home together."
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Product Image Hero
                productImageHero

                VStack(alignment: .leading, spacing: 20) {
                    // Title + Badge + Price
                    productHeader

                    // Meaningful text
                    meaningSection

                    // Group Gift Progress (if applicable)
                    if giftItem.isGroupGift {
                        groupGiftProgress
                    }

                    Divider().opacity(0.15)

                    // Purchase options
                    purchaseOptions

                    // Gift message toggle
                    giftMessageSection

                    // CTA
                    continueButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.wsBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToCheckout) {
            GuestCheckoutView(
                giftItem: giftItem,
                registry: registry,
                isContribution: isGroupContribute,
                contributionAmount: isGroupContribute ? (Double(contributionText) ?? 0) : giftItem.item.price,
                giftMessage: showGiftMessage ? giftMessage : nil
            )
            .environmentObject(registryRepo)
        }
        .onAppear {
            contributionAmount = giftItem.item.price / 2
            contributionText = String(format: "%.0f", contributionAmount)
        }
    }

    // MARK: - Subviews

    private var productImageHero: some View {
        ZStack(alignment: .topTrailing) {
            CustomAsyncImage(url: imageURL)
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .clipped()

            // Badge overlay
            HStack(spacing: 5) {
                Text(giftItem.badge.emoji)
                Text(giftItem.badge.label)
                    .font(WSFont.label(12))
                    .fontWeight(.semibold)
            }
            .foregroundStyle(giftItem.badge.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial)
            .clipShape(Capsule(style: .continuous))
            .padding(16)
        }
    }

    private var productHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(giftItem.item.title)
                .font(WSFont.heading(22))
                .foregroundStyle(Color.wsNavy)

            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "$%.2f", giftItem.item.price))
                    .font(WSFont.price(22))
                    .foregroundStyle(Color.wsAccent)
                Spacer()
                // Score chip
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                    Text("Score \(Int(giftItem.score))/100")
                        .font(WSFont.label(11))
                }
                .foregroundStyle(Color.wsTextSecondary)
            }
        }
    }

    private var meaningSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Why this gift is special")
                .font(WSFont.subheading(14))
                .foregroundStyle(Color.wsNavy)
            Text(meaningfulText)
                .font(WSFont.body(14))
                .foregroundStyle(Color.wsTextSecondary)
                .lineSpacing(3)
        }
        .padding(14)
        .background(Color.wsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var groupGiftProgress: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Group Gift Progress")
                    .font(WSFont.subheading(14))
                    .foregroundStyle(Color.wsNavy)
                Spacer()
                if let remaining = giftItem.remainingAmount {
                    Text("$\(String(format: "%.0f", remaining)) needed")
                        .font(WSFont.caption(12))
                        .foregroundStyle(giftItem.isNearlyFunded ? Color.wsSuccess : Color.wsTextSecondary)
                        .fontWeight(giftItem.isNearlyFunded ? .semibold : .regular)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.wsSurface)
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: giftItem.isNearlyFunded
                                    ? [Color.wsSuccess, Color.wsSuccess.opacity(0.7)]
                                    : [Color.wsAccent, Color(red: 0.62, green: 0.44, blue: 0.30)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * giftItem.fundingProgress, height: 10)
                }
            }
            .frame(height: 10)

            if let funded = giftItem.groupFunded, let total = giftItem.groupTotal {
                Text("$\(String(format: "%.0f", funded)) of $\(String(format: "%.0f", total)) contributed by guests")
                    .font(WSFont.caption(12))
                    .foregroundStyle(Color.wsTextSecondary)
            }
        }
    }

    private var purchaseOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Gift Options")
                .font(WSFont.subheading(14))
                .foregroundStyle(Color.wsNavy)

            // Buy full vs contribute toggle
            VStack(spacing: 10) {
                optionRow(
                    selected: !isGroupContribute,
                    icon: "gift.fill",
                    title: "Buy Entire Gift",
                    subtitle: String(format: "$%.2f — Ship directly to them", giftItem.item.price)
                ) {
                    withAnimation(WSAnimation.spring) { isGroupContribute = false }
                }

                if giftItem.isGroupGift {
                    optionRow(
                        selected: isGroupContribute,
                        icon: "person.2.fill",
                        title: "Contribute to Group Gift",
                        subtitle: "Add any amount toward the total"
                    ) {
                        withAnimation(WSAnimation.spring) { isGroupContribute = true }
                    }

                    if isGroupContribute {
                        contributionAmountField
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
        }
    }

    private func optionRow(selected: Bool, icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(selected ? Color.wsNavy : Color.wsSurface)
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(selected ? Color.white : Color.wsTextSecondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(WSFont.subheading(14))
                        .foregroundStyle(Color.wsNavy)
                    Text(subtitle)
                        .font(WSFont.caption(12))
                        .foregroundStyle(Color.wsTextSecondary)
                }

                Spacer()

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(selected ? Color.wsNavy : Color.wsMuted)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? Color.wsNavy.opacity(0.04) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        selected ? Color.wsNavy.opacity(0.25) : Color.wsBorder.opacity(0.6),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(WSAnimation.spring, value: selected)
    }

    private var contributionAmountField: some View {
        HStack {
            Text("$")
                .font(WSFont.subheading(18))
                .foregroundStyle(Color.wsNavy)
            TextField("Amount", text: $contributionText)
                .font(WSFont.subheading(18))
                .keyboardType(.numberPad)
                .foregroundStyle(Color.wsNavy)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.wsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.wsBorder, lineWidth: 1)
        )
    }

    private var giftMessageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(WSAnimation.spring) { showGiftMessage.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.wsAccent)
                    Text("Add a gift message")
                        .font(WSFont.subheading(14))
                        .foregroundStyle(Color.wsNavy)
                    Spacer()
                    Image(systemName: showGiftMessage ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.wsMuted)
                }
            }
            .buttonStyle(.plain)

            if showGiftMessage {
                TextField("Write something heartfelt…", text: $giftMessage, axis: .vertical)
                    .font(WSFont.body(14))
                    .foregroundStyle(Color.wsNavy)
                    .lineLimit(4...6)
                    .padding(12)
                    .background(Color.wsSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.wsBorder, lineWidth: 1)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var continueButton: some View {
        Button {
            navigateToCheckout = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Continue to Checkout")
                    .font(WSFont.subheading(17))
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(WSGradient.button)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var imageURL: URL? {
        guard let path = giftItem.item.imageUrl else { return nil }
        return URL(string: AppConstants.API.imageBasePath + path)
    }
}
