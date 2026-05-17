//
//  CartView.swift
//  WSHackathonApp
//

import SwiftUI

struct CartView: View {
    @StateObject private var viewModel = CartViewModel()
    @EnvironmentObject var cartRepository: CartRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    @State private var navigateToCheckout = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isEmptyCart {
                    WSEmptyState(
                        title: "Your Cart is Empty",
                        systemImage: "bag",
                        message: "Add beautiful pieces from our curated collection."
                    )
                    .wsAppBackground()
                } else {
                    List {
                        Section {
                            ForEach(viewModel.items) { item in
                                CartItemRow(
                                    item: item,
                                    onAdd: { viewModel.add(item) },
                                    onRemove: { viewModel.removeItem(item) }
                                )
                                .padding(16)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(WSGradient.cardStroke, lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation(.spring(response: 0.35)) {
                                            viewModel.removeCompletely(item)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            Text("\(viewModel.items.count) \(viewModel.items.count == 1 ? "Item" : "Items")")
                                .font(WSFont.caption(12))
                                .foregroundStyle(Color.wsTextSecondary)
                                .textCase(nil)
                        }
                        

                        // MARK: - Inspiration Section
                        if viewModel.showRecommendations || viewModel.items.count > 0 {
                            Section {
                                VStack(spacing: 8) {
                                    if viewModel.showRecommendations {
                                        if viewModel.isLoadingRecommendations {
                                            ShimmerRecommendationSection()
                                                .transition(.opacity)
                                        } else if let recommendation = viewModel.recommendation,
                                                  !recommendation.products.isEmpty {
                                            CartRecommendationView(
                                                recommendation: recommendation,
                                                onAddProduct: { product in
                                                    viewModel.addRecommendation(product)
                                                },
                                                onAddAll: {
                                                    viewModel.addAllRecommendations()
                                                }
                                            )
                                            .transition(.move(edge: .bottom).combined(with: .opacity))
                                        }
                                    }
                                    
                                    if viewModel.items.count > 0 {
                                        ExpandableRecipeCard(
                                            recipe: viewModel.generatedRecipe,
                                            isLoading: viewModel.isGeneratingRecipe
                                        )
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 12, trailing: 0))
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .wsAppBackground()
                    .safeAreaInset(edge: .bottom) {
                        WSCheckoutBar(
                            totalLabel: AppStrings.Cart.total,
                            totalValue: viewModel.totalPriceText,
                            buttonTitle: AppStrings.Cart.checkoutButton,
                            action: { navigateToCheckout = true }
                        )
                    }
                }
            }

            .navigationTitle(AppStrings.Cart.title)
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $navigateToCheckout) {
                CartCheckoutView(
                    items: viewModel.items,
                    totalAmount: viewModel.totalPrice,
                    onCheckoutSuccess: {
                        cartRepository.clear()
                        navigateToCheckout = false
                    }
                )
            }
        }
        .onAppear {
            viewModel.bind(repository: cartRepository)
        }
    }
}

// MARK: - Expandable Recipe Card

struct ExpandableRecipeCard: View {
    let recipe: CartGeneratedRecipe?
    let isLoading: Bool
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    if !isLoading && recipe != nil {
                        isExpanded.toggle()
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.wsSurface)
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.wsAccent)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CULINARY INSPIRATION")
                            .font(WSFont.caption(9))
                            .foregroundStyle(Color.wsAccent)
                            .textCase(.uppercase)
                            .tracking(1.5)
                        
                        if isLoading {
                            Text("Cooking up an idea...")
                                .font(WSFont.subheading(14))
                                .foregroundStyle(Color.wsNavy)
                            
                            ProgressView()
                                .tint(Color.wsAccent)
                                .scaleEffect(0.6, anchor: .leading)
                        } else if let recipe = recipe {
                            Text(recipe.title)
                                .font(WSFont.heading(15))
                                .foregroundStyle(Color.wsNavy)
                                .multilineTextAlignment(.leading)
                        } else {
                            Text("Add more items to get a recipe")
                                .font(WSFont.subheading(14))
                                .foregroundStyle(Color.wsNavy)
                        }
                    }
                    
                    Spacer()
                    
                    if !isLoading && recipe != nil {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundStyle(Color.wsTextSecondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.clear)
            }
            .buttonStyle(.plain)
            
            if isExpanded, let recipe = recipe {
                Divider()
                    .padding(.horizontal, 16)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text(recipe.description)
                        .font(WSFont.body(14))
                        .foregroundStyle(Color.wsTextSecondary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ingredients")
                            .font(WSFont.heading(16))
                            .foregroundStyle(Color.wsNavy)
                        
                        ForEach(recipe.ingredients, id: \.self) { ingredient in
                            HStack(alignment: .top) {
                                Circle()
                                    .fill(Color.wsAccent)
                                    .frame(width: 5, height: 5)
                                    .padding(.top, 6)
                                Text(ingredient)
                                    .font(WSFont.body(14))
                                    .foregroundStyle(Color.wsText)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instructions")
                            .font(WSFont.heading(16))
                            .foregroundStyle(Color.wsNavy)
                        
                        ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(WSFont.caption(12))
                                    .foregroundStyle(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Color.wsNavy)
                                    .clipShape(Circle())
                                
                                Text(instruction)
                                    .font(WSFont.body(14))
                                    .foregroundStyle(Color.wsText)
                                    .lineSpacing(4)
                            }
                        }
                    }
                }
                .padding(20)
                .background(Color.wsSurface.opacity(0.3))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(WSGradient.cardStroke, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
    }
}


// MARK: - Cart Checkout View

struct CartCheckoutView: View {
    let items: [CartItem]
    let totalAmount: Double
    let onCheckoutSuccess: () -> Void

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var address: String = ""
    @State private var isProcessing = false
    @State private var navigateToSuccess = false
    @State private var pulseAnimation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Order Summary
                orderSummaryCard

                // Shipping Details
                detailsSection

                // Account benefits note
                benefitsNote

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
            CartPurchaseSuccessView(
                purchasedItems: items,
                amount: totalAmount,
                customerName: name.isEmpty ? "A guest" : name,
                onComplete: onCheckoutSuccess
            )
        }
    }

    // MARK: - Subviews

    private var orderSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Order Summary")
                .font(WSFont.subheading(16))
                .foregroundStyle(Color.wsNavy)

            ForEach(items) { item in
                HStack(alignment: .top, spacing: 14) {
                    CustomAsyncImage(url: item.imageURL)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Color.wsBorder, lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(WSFont.body(13))
                            .foregroundStyle(Color.wsNavy)
                            .lineLimit(2)
                        
                        HStack {
                            Text("Qty: \(item.quantity)")
                                .font(WSFont.caption(12))
                                .foregroundStyle(Color.wsTextSecondary)
                            Spacer()
                            Text(String(format: "$%.2f", item.price * Double(item.quantity)))
                                .font(WSFont.price(13))
                                .foregroundStyle(Color.wsNavy)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if item.id != items.last?.id {
                    Divider().opacity(0.1)
                }
            }

            Divider().opacity(0.15)

            // Line items
            VStack(spacing: 8) {
                lineItem(label: "Subtotal", value: String(format: "$%.2f", totalAmount))
                lineItem(label: "Shipping", value: "Free Standard")
                lineItem(label: "Tax", value: "Calculated at purchase")
            }

            Divider().opacity(0.15)

            HStack {
                Text("Total")
                    .font(WSFont.subheading(16))
                    .foregroundStyle(Color.wsNavy)
                Spacer()
                Text(String(format: "$%.2f", totalAmount))
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

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shipping & Contact")
                .font(WSFont.subheading(14))
                .foregroundStyle(Color.wsNavy)

            VStack(spacing: 10) {
                WSTextField(placeholder: "Your Name", text: $name)
                WSTextField(placeholder: "Email Address", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                WSTextField(placeholder: "Shipping Address", text: $address)
            }
        }
        .padding(.horizontal, 20)
    }

    private var benefitsNote: some View {
        HStack(spacing: 10) {
            Image(systemName: "shield.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.wsAccent)
            VStack(alignment: .leading, spacing: 2) {
                Text("Secure Checkout")
                    .font(WSFont.subheading(13))
                    .foregroundStyle(Color.wsAccent)
                Text("Your transaction is encrypted securely to protect your purchase.")
                    .font(WSFont.caption(12))
                    .foregroundStyle(Color.wsTextSecondary)
            }
        }
        .padding(14)
        .background(Color.wsAccent.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.wsAccent.opacity(0.15), lineWidth: 1)
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
            navigateToSuccess = true
        }
    }

}

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


// MARK: - Cart Purchase Success View

struct CartPurchaseSuccessView: View {
    let purchasedItems: [CartItem]
    let amount: Double
    let customerName: String
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var particles: [ConfettiParticle] = []
    @State private var animateIn = false

    var headline: String {
        "Order Confirmed! 🎉"
    }

    var subheadline: String {
        "Thank you for shopping with Williams-Sonoma. Your gorgeous new pieces are being prepared."
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
                    // Animated success header
                    successIconHeader

                    // Success message
                    successMessage

                    // Receipt card
                    receiptCard

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
                Button("Done") {
                    onComplete()
                }
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
    }

    // MARK: - Subviews

    private var successIconHeader: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.wsSuccess.opacity(0.15), Color.wsBackground],
                        center: .center, startRadius: 20, endRadius: 80
                    )
                )
                .frame(width: 140, height: 140)

            Text("🛍️")
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
                .font(WSFont.body(15))
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
                Text("Payment Confirmed")
                    .font(WSFont.subheading(16))
                    .foregroundStyle(Color.wsNavy)
                Spacer()
            }

            Divider().opacity(0.15)

            receiptRow(icon: "bag", label: "Items Purchased", value: "\(purchasedItems.count) item(s)")
            receiptRow(icon: "shippingbox", label: "Shipping", value: "Free Standard")
            receiptRow(icon: "dollarsign.circle", label: "Amount Paid", value: String(format: "$%.2f", amount))
            receiptRow(icon: "person.fill", label: "Delivering To", value: customerName)
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


    // MARK: - Confetti

    private func spawnConfetti() {
        particles = (0..<30).map { _ in ConfettiParticle() }
    }
}


