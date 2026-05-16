//
//  PurchaseSuccessView.swift
//  WSHackathonApp
//

import SwiftUI

struct PurchaseSuccessView: View {
    let giftItem: GiftabilityItem
    let registry: Registry
    let guestName: String
    let isContribution: Bool
    let amount: Double

    @EnvironmentObject var registryRepo: RegistryRepository
    @Environment(\.dismiss) private var dismiss

    @State private var particles: [ConfettiParticle] = []
    @State private var animateIn = false
    @State private var showKeyRewards = false

    var coupleFirstName: String { registry.firstName }
    var coupleName: String { registry.displayName }

    var headline: String {
        isContribution
            ? "Thank you for contributing! 🎉"
            : "Your gift is on its way! 🎁"
    }

    var subheadline: String {
        isContribution
            ? "You just helped \(coupleFirstName) get closer to their dream \(shortItemName)!"
            : "You just helped complete \(coupleFirstName)'s dream kitchen."
    }

    var shortItemName: String {
        let title = giftItem.item.title
        let words = title.components(separatedBy: " ")
        return words.prefix(3).joined(separator: " ")
    }

    var body: some View {
        ZStack {
            Color.wsBackground.ignoresSafeArea()

            // Confetti
            ForEach(particles) { p in
                ConfettiDot(particle: p)
            }

            ScrollView {
                VStack(spacing: 32) {
                    // Animated gift icon
                    giftIconHeader

                    // Success message
                    successMessage

                    // Receipt card
                    receiptCard

                    // Action cards
                    actionCards

                    Spacer(minLength: 40)
                }
                .padding(.top, 40)
                .padding(.horizontal, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .font(WSFont.body(15))
                    .foregroundStyle(Color.wsNavy)
            }
        }
        .onAppear {
            spawnConfetti()
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.1)) {
                animateIn = true
            }
        }
        .sheet(isPresented: $showKeyRewards) {
            KeyRewardsSheet()
        }
    }

    // MARK: - Subviews

    private var giftIconHeader: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.wsAccent.opacity(0.2), Color.wsBackground],
                        center: .center, startRadius: 20, endRadius: 80
                    )
                )
                .frame(width: 140, height: 140)

            Text("🎁")
                .font(.system(size: 72))
                .scaleEffect(animateIn ? 1.0 : 0.3)
                .rotationEffect(.degrees(animateIn ? 0 : -30))
        }
    }

    private var successMessage: some View {
        VStack(spacing: 10) {
            Text(headline)
                .font(WSFont.heading(26))
                .foregroundStyle(Color.wsNavy)
                .multilineTextAlignment(.center)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)

            Text("\"" + subheadline + "\"")
                .font(WSFont.body(16))
                .foregroundStyle(Color.wsTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 8)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 14)
        }
        .animation(WSAnimation.spring.delay(0.2), value: animateIn)
    }

    private var receiptCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.wsSuccess)
                Text("Gift Confirmed")
                    .font(WSFont.subheading(16))
                    .foregroundStyle(Color.wsNavy)
                Spacer()
            }

            Divider().opacity(0.15)

            receiptRow(icon: "gift", label: "Item", value: shortItemName)
            if !isContribution {
                receiptRow(icon: "shippingbox", label: "Ships to", value: coupleFirstName + " & " + registry.lastName)
            }
            receiptRow(icon: "dollarsign.circle", label: isContribution ? "Contributed" : "Amount", value: String(format: "$%.2f", amount))
            receiptRow(icon: "person.fill", label: "From", value: guestName)
        }
        .padding(18)
        .background(WSCardBackground(cornerRadius: 16))
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(WSAnimation.spring.delay(0.35), value: animateIn)
    }

    private func receiptRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Color.wsAccent)
                .frame(width: 18)
            Text(label)
                .font(WSFont.body(14))
                .foregroundStyle(Color.wsTextSecondary)
            Spacer()
            Text(value)
                .font(WSFont.body(14))
                .foregroundStyle(Color.wsNavy)
                .fontWeight(.medium)
                .lineLimit(1)
        }
    }

    private var actionCards: some View {
        VStack(spacing: 12) {
            // Discover WS
            actionCard(
                icon: "bag.fill",
                title: "Discover Williams-Sonoma",
                subtitle: "Explore our full collection of kitchen & home essentials",
                color: Color.wsNavy
            ) { dismiss() }

            // Key Rewards
            actionCard(
                icon: "star.fill",
                title: "Join Key Rewards",
                subtitle: "Earn rewards on every WS purchase — free to join",
                color: Color.wsAccent
            ) { showKeyRewards = true }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(WSAnimation.spring.delay(0.5), value: animateIn)
    }

    private func actionCard(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(WSFont.subheading(14))
                        .foregroundStyle(Color.wsNavy)
                    Text(subtitle)
                        .font(WSFont.caption(12))
                        .foregroundStyle(Color.wsTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.wsMuted)
            }
            .padding(16)
            .background(Color.wsCard)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.wsBorder.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Confetti

    private func spawnConfetti() {
        particles = (0..<30).map { _ in ConfettiParticle() }
    }
}

// MARK: - Confetti Particle

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat = CGFloat.random(in: 0...UIScreen.main.bounds.width)
    let delay: Double = Double.random(in: 0...0.8)
    let color: Color = [Color.wsAccent, Color.wsSuccess, Color(.systemYellow), Color(.systemPink), Color.wsNavy].randomElement()!
    let size: CGFloat = CGFloat.random(in: 6...14)
    let rotation: Double = Double.random(in: 0...360)
}

struct ConfettiDot: View {
    let particle: ConfettiParticle
    @State private var drop = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(particle.color.opacity(0.85))
            .frame(width: particle.size, height: particle.size * 0.5)
            .rotationEffect(.degrees(particle.rotation))
            .position(x: particle.x, y: drop ? UIScreen.main.bounds.height + 60 : -40)
            .animation(
                .linear(duration: Double.random(in: 1.8...3.0))
                .delay(particle.delay)
                .repeatForever(autoreverses: false),
                value: drop
            )
            .onAppear { drop = true }
    }
}

// MARK: - Key Rewards Sheet

private struct KeyRewardsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.wsAccent)
                    .padding(.top, 40)

                VStack(spacing: 8) {
                    Text("Join Key Rewards")
                        .font(WSFont.heading(26))
                        .foregroundStyle(Color.wsNavy)
                    Text("Earn points on every purchase at Williams-Sonoma, Pottery Barn, West Elm, and more.")
                        .font(WSFont.body(15))
                        .foregroundStyle(Color.wsTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                WSPrimaryButton(title: "Create Account & Join", icon: "person.badge.plus") {
                    dismiss()
                }
                .padding(.horizontal, 24)

                Button("Maybe Later") { dismiss() }
                    .font(WSFont.body(15))
                    .foregroundStyle(Color.wsTextSecondary)

                Spacer()
            }
            .background(Color.wsBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
