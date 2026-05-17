//
//  GuestCheckoutView.swift
//  WSHackathonApp
//

import SwiftUI

struct GuestCheckoutView: View {
    let giftItem: GiftabilityItem
    let registry: Registry
    let isContribution: Bool
    let contributionAmount: Double
    let giftMessage: String?
    var onDone: (() -> Void)? = nil

    @EnvironmentObject var registryRepo: RegistryRepository
    @State private var guestName: String = ""
    @State private var guestEmail: String = ""
    @State private var isProcessing = false
    @State private var navigateToSuccess = false
    @State private var pulseAnimation = false

    private var displayAmount: Double {
        isContribution ? contributionAmount : giftItem.item.price
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Order Summary
                orderSummaryCard

                // Autofill Fields
                guestInfoSection

                // No account reminder
                noAccountNote

                // Apple Pay Button
                applePayButton

                // Terms note
                Text("By purchasing, you agree to Williams-Sonoma's Terms of Service and Privacy Policy.")
                    .font(WSFont.caption(11))
                    .foregroundStyle(Color.wsMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
            .padding(.top, 16)
        }
        .background(Color.wsBackground.ignoresSafeArea())
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToSuccess) {
            PurchaseSuccessView(
                giftItem: giftItem,
                registry: registry,
                guestName: guestName.isEmpty ? "A guest" : guestName,
                isContribution: isContribution,
                amount: displayAmount,
                onDone: onDone
            )
            .environmentObject(registryRepo)
        }
    }

    // MARK: - Subviews

    private var orderSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Order Summary")
                .font(WSFont.subheading(16))
                .foregroundStyle(Color.wsNavy)

            HStack(alignment: .top, spacing: 14) {
                CustomAsyncImage(url: imageURL)
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(giftItem.item.title)
                        .font(WSFont.body(14))
                        .foregroundStyle(Color.wsNavy)
                        .lineLimit(2)
                    if isContribution {
                        Text("Group gift contribution")
                            .font(WSFont.caption(12))
                            .foregroundStyle(Color.wsTextSecondary)
                    } else {
                        Text("Full gift • Ships to couple")
                            .font(WSFont.caption(12))
                            .foregroundStyle(Color.wsTextSecondary)
                    }
                    if let msg = giftMessage, !msg.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 10))
                            Text("Gift message included")
                                .font(WSFont.caption(11))
                        }
                        .foregroundStyle(Color.wsAccent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider().opacity(0.15)

            // Line items
            VStack(spacing: 8) {
                lineItem(label: isContribution ? "Contribution" : "Gift Price",
                         value: String(format: "$%.2f", displayAmount))
                lineItem(label: "Shipping", value: "Free 🎁")
                lineItem(label: "Tax", value: "Calculated at purchase")
            }

            Divider().opacity(0.15)

            HStack {
                Text("Total")
                    .font(WSFont.subheading(16))
                    .foregroundStyle(Color.wsNavy)
                Spacer()
                Text(String(format: "$%.2f", displayAmount))
                    .font(WSFont.display(22))
                    .foregroundStyle(Color.wsNavy)
            }
        }
        .padding(18)
        .background(WSCardBackground(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    private func lineItem(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(WSFont.body(14))
                .foregroundStyle(Color.wsTextSecondary)
            Spacer()
            Text(value)
                .font(WSFont.body(14))
                .foregroundStyle(Color.wsNavy)
                .fontWeight(.medium)
        }
    }

    private var guestInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Details (Optional)")
                .font(WSFont.subheading(14))
                .foregroundStyle(Color.wsNavy)

            VStack(spacing: 10) {
                WSTextField(placeholder: "Your name (so the couple knows!)", text: $guestName)
                WSTextField(placeholder: "Email for receipt (optional)", text: $guestEmail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
        }
        .padding(.horizontal, 20)
    }

    private var noAccountNote: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.wsSuccess)
            VStack(alignment: .leading, spacing: 2) {
                Text("No account required")
                    .font(WSFont.subheading(13))
                    .foregroundStyle(Color.wsSuccess)
                Text("You can create a Williams-Sonoma account after your purchase for exclusive perks.")
                    .font(WSFont.caption(12))
                    .foregroundStyle(Color.wsTextSecondary)
            }
        }
        .padding(14)
        .background(Color.wsSuccess.opacity(0.07))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.wsSuccess.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 20)
    }

    private var applePayButton: some View {
        VStack(spacing: 12) {
            Button {
                guard !isProcessing else { return }
                processPayment()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.black)
                        .frame(height: 56)
                        .scaleEffect(pulseAnimation ? 1.02 : 1.0)
                        .shadow(color: Color.black.opacity(0.25), radius: 12, y: 4)

                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(1.1)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "applelogo")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white)
                            Text("Pay")
                                .font(.system(size: 20, weight: .medium, design: .default))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 20)
            .animation(WSAnimation.spring, value: pulseAnimation)
            .animation(WSAnimation.spring, value: isProcessing)
        }
    }

    // MARK: - Actions

    private func processPayment() {
        isProcessing = true
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            pulseAnimation = false
            isProcessing = false

            let gift = GuestGift(
                registryId: registry.id,
                itemId: giftItem.item.id,
                contributionAmount: displayAmount,
                guestName: guestName.isEmpty ? "A guest" : guestName,
                message: giftMessage,
                isPurchased: !isContribution,
                isContribution: isContribution
            )
            registryRepo.recordPurchase(gift: gift)
            navigateToSuccess = true
        }
    }

    private var imageURL: URL? {
        guard let path = giftItem.item.imageUrl else { return nil }
        return URL(string: AppConstants.API.imageBasePath + path)
    }
}

// MARK: - Reusable text field

private struct WSTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: UITextAutocapitalizationType = .words

    var body: some View {
        TextField(placeholder, text: $text)
            .font(WSFont.body(15))
            .foregroundStyle(Color.wsNavy)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Color.wsBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.wsBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
