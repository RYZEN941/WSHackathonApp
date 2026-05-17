//
//  GiftabilityItemCard.swift
//  WSHackathonApp
//

import SwiftUI

struct GiftabilityItemCard: View {
    let item: GiftabilityItem
    let onBuyNow: () -> Void
    let onContribute: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                // Product Image
                CustomAsyncImage(url: imageURL)
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.wsNavy.opacity(0.08), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    // Badge
                    HStack(spacing: 4) {
                        Text(item.badge.emoji)
                            .font(.caption)
                        Text(item.badge.label)
                            .font(WSFont.label(11))
                            .foregroundStyle(item.badge.color)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(item.badge.backgroundColor)
                    .clipShape(Capsule(style: .continuous))

                    // Title
                    Text(item.item.title)
                        .font(WSFont.body(14))
                        .foregroundStyle(Color.wsNavy)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    // Price
                    Text(String(format: "$%.2f", item.item.price))
                        .font(WSFont.price(15))
                        .foregroundStyle(Color.wsAccent)
                    
                    // Social Proof Context
                    HStack(spacing: 5) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.wsTextSecondary)
                        Text(item.socialProof)
                            .font(WSFont.caption(11))
                            .foregroundStyle(Color.wsTextSecondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)

            // Group Gift Progress (if applicable)
            if item.isGroupGift {
                groupGiftSection
            }

            Divider()
                .padding(.horizontal, 14)
                .opacity(0.15)

            // CTAs Row
            HStack {
                Spacer()

                HStack(spacing: 8) {
                    if item.isGroupGift {
                        Button(action: onContribute) {
                            Text("Contribute")
                                .font(WSFont.caption(12))
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.wsNavy)
                                .lineLimit(1)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                                .background(Color.wsSurface)
                                .overlay(
                                    Capsule(style: .continuous)
                                        .strokeBorder(Color.wsBorder, lineWidth: 1)
                                )
                                .clipShape(Capsule(style: .continuous))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }

                    Button(action: onBuyNow) {
                        HStack(spacing: 5) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text(item.isGroupGift ? "Buy Full" : "Gift Now")
                                .font(WSFont.caption(12))
                                .fontWeight(.semibold)
                                .lineLimit(1)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(WSGradient.button)
                        .clipShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(WSCardBackground(cornerRadius: 16))
    }

    // MARK: - Group Gift Progress

    private var groupGiftSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Progress bar
            // Progress bar (Solid scale layout, eliminating GeometryReader feedback loops)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.wsSurface)
                    .frame(height: 6)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: item.isNearlyFunded
                                ? [Color.wsSuccess, Color.wsSuccess.opacity(0.7)]
                                : [Color.wsAccent, Color(red: 0.62, green: 0.44, blue: 0.30)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 6)
                    .scaleEffect(x: CGFloat(item.fundingProgress), y: 1.0, anchor: .leading)
            }
            .frame(height: 6)

            HStack {
                if let remaining = item.remainingAmount {
                    Text(item.isNearlyFunded ? "🔥 Only $\(String(format: "%.0f", remaining)) left to complete!" : "$\(String(format: "%.0f", remaining)) remaining")
                        .font(WSFont.caption(11))
                        .foregroundStyle(item.isNearlyFunded ? Color.wsSuccess : Color.wsTextSecondary)
                        .fontWeight(item.isNearlyFunded ? .semibold : .regular)
                }
                Spacer()
                if let funded = item.groupFunded, let total = item.groupTotal {
                    Text("$\(String(format: "%.0f", funded)) of $\(String(format: "%.0f", total)) funded")
                        .font(WSFont.caption(11))
                        .foregroundStyle(Color.wsTextSecondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    private var imageURL: URL? {
        guard let path = item.item.imageUrl else { return nil }
        return URL(string: AppConstants.API.imageBasePath + path)
    }
}
