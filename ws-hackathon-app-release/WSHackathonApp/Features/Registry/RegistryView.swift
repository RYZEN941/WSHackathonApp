//
//  RegistryView.swift
//  WSHackathonApp
//

import SwiftUI

enum RegistryRoute: Hashable {
    case create
    case success
    case smartRegistry
}

struct RegistryView: View {
    @StateObject private var viewModel = RegistryViewModel()
    @EnvironmentObject var registryRepo: RegistryRepository
    @EnvironmentObject var cartRepo: CartRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    
    @State private var showRegistryDetail = false
    @State private var showShareSheet = false
    @State private var showGuestView = false
    @State private var roomCodeInput = ""
    @State private var joinStatusMessage: String? = nil
    @State private var joinSuccess = false
    
    private let rowInsets = EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20)
    
    var body: some View {
        NavigationStack(path: $tabBarVM.registryPath) {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.hasRegistry {
                        if showRegistryDetail {
                            registryContent
                                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                      removal: .move(edge: .trailing).combined(with: .opacity)))
                        } else {
                            VStack(spacing: 20) {
                                ForEach(viewModel.registries) { registry in
                                    registryDashboardView(for: registry)
                                }
                            }
                            .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                                                  removal: .move(edge: .leading).combined(with: .opacity)))
                        }
                    } else {
                        noRegistryContent
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color.wsBackground.ignoresSafeArea())
            .navigationTitle(showRegistryDetail ? viewModel.displayTitle : AppStrings.Registry.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                    if showRegistryDetail {
                        ToolbarItem(placement: .topBarTrailing) {
                            HStack(spacing: 14) {
                                // Share button
                                Button {
                                    showShareSheet = true
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(Color.wsNavy)
                                }
                                // Delete button
                                Button("Delete", role: .destructive) {
                                    withAnimation(WSAnimation.spring) {
                                        viewModel.deleteRegistry(using: registryRepo)
                                        showRegistryDetail = false
                                    }
                                }
                                .font(WSFont.body(15))
                            }
                        }
                    } else {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                tabBarVM.registryPath.append(.create)
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Color.wsNavy)
                            }
                        }
                    }
                    
                    if showRegistryDetail {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                withAnimation(WSAnimation.spring) {
                                    showRegistryDetail = false
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Color.wsNavy)
                            }
                    }
                }
            }
            .navigationDestination(for: RegistryRoute.self) { route in
                switch route {
                case .create:
                    CreateRegistryView()
                case .success:
                    RegistrySuccessView()
                case .smartRegistry:
                    SmartRegistryView()
                }
            }
        }
        .onAppear {
            viewModel.bind(repository: registryRepo)
        }
        .onChange(of: registryRepo.pendingGuestViewCode) { _, code in
            if code != nil {
                showGuestView = true
                registryRepo.pendingGuestViewCode = nil
            }
        }
        .animation(WSAnimation.spring, value: viewModel.hasRegistry)
        .animation(WSAnimation.spring, value: showRegistryDetail)
        .sheet(isPresented: $showShareSheet) {
            if let registry = registryRepo.currentRegistry {
                ShareRegistrySheet(
                    registryName: registry.displayName,
                    shareCode: registryRepo.shareCode
                )
            }
        }
        .fullScreenCover(isPresented: $showGuestView) {
            if let registry = registryRepo.currentRegistry {
                GuestRegistryView(registry: registry)
                    .environmentObject(registryRepo)
            }
        }
    }
}

// MARK: - Components
private extension RegistryView {
    
    @ViewBuilder
    var registryContent: some View {
        VStack(spacing: 0) {
            // MARK: - Notifications Banner
            if !registryRepo.notifications.isEmpty {
                notificationsBanner
                    .padding(.top, 8)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // MARK: - Guest Preview Button
            guestPreviewButton
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 4)

            // MARK: - Header with AI Button and Budget
            VStack(spacing: 16) {
                aiGiftFinderButton
                
                if viewModel.hasBudget {
                    budgetProgressView
                }
            }
            .padding(.vertical, 16)
            
            if viewModel.hasItems {
                registryItemsList
            } else {
                emptyItemsView
            }
        }
    }
    
    var registryItemsList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.items) { item in
                RegistryItemRow(
                    viewModel: RegistryItemRowViewModel(
                        item: item,
                        registryRepo: registryRepo,
                        cartRepo: cartRepo,
                        tabbarVM: tabBarVM
                    )
                )
                .padding(12)
                .background(WSCardBackground(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.wsNavy.opacity(0.06), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    var emptyItemsView: some View {
        WSEmptyState(
            title: "Your Registry is Empty",
            systemImage: "gift",
            message: "Browse our collection and tap the gift icon to add favorites.",
            buttonTitle: "Browse Collection",
            action: { tabBarVM.selectTab(.home) }
        )
    }
    
    @ViewBuilder
    func registryDashboardView(for registry: Registry) -> some View {
        Button {
            withAnimation(WSAnimation.spring) {
                registryRepo.selectRegistry(registry.id)
                showRegistryDetail = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                // Header Section
                VStack(alignment: .leading, spacing: 4) {
                    Text(registry.date.formatted(date: .abbreviated, time: .omitted))
                        .font(WSFont.caption(12))
                        .foregroundStyle(Color.wsAccent)
                        .fontWeight(.medium)
                    
                    Text(registry.displayName)
                        .font(WSFont.subheading(20))
                        .foregroundStyle(Color.wsNavy)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Divider()
                    .padding(.horizontal, 20)
                    .opacity(0.1)
                
                // Info Section
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(registry.items.count)")
                            .font(WSFont.subheading(20))
                            .foregroundStyle(Color.wsNavy)
                        Text("Items")
                            .font(WSFont.caption(12))
                            .foregroundStyle(Color.wsTextSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("$\(String(format: "%.0f", registry.totalValue))")
                            .font(WSFont.subheading(20))
                            .foregroundStyle(Color.wsNavy)
                        Text("Total Value")
                            .font(WSFont.caption(12))
                            .foregroundStyle(Color.wsTextSecondary)
                    }
                    
                    if let budget = registry.budget {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("$\(String(format: "%.0f", budget))")
                                .font(WSFont.subheading(20))
                                .foregroundStyle(Color.wsAccent)
                            Text("Budget")
                                .font(WSFont.caption(12))
                                .foregroundStyle(Color.wsTextSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.wsMuted)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.wsCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.wsBorder.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 20)
    }

    var noRegistryContent: some View {
        VStack(spacing: 0) {
            WSRegistryHeroCard {
                tabBarVM.registryPath.append(.create)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            WSSectionHeader(
                title: "Top Reasons to Register",
                subtitle: "Everything you need for your special day"
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            ForEach(Array(viewModel.instructions.enumerated()), id: \.element.id) { index, item in
                RegistryReasonCard(
                    number: index + 1,
                    title: item.title,
                    description: item.description
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .padding(.bottom, 40)
    }
    
    var aiGiftFinderButton: some View {
        Button {
            tabBarVM.registryPath.append(.smartRegistry)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.3, green: 0.2, blue: 0.5), Color(red: 0.5, green: 0.35, blue: 0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "sparkles")
                        .font(.body)
                        .foregroundColor(.yellow)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(AppStrings.SmartRegistry.aiGiftFinder)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Get AI-curated gift bundles within your budget")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color(red: 0.35, green: 0.25, blue: 0.55).opacity(0.15), radius: 6, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 0.35, green: 0.25, blue: 0.55).opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }
    
    var budgetProgressView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Registry Budget")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let remaining = viewModel.remainingBudget {
                    Text("$\(String(format: "%.2f", remaining)) remaining")
                        .font(.caption)
                        .foregroundColor(remaining > 0 ? .green : .red)
                        .fontWeight(.medium)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 10)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: viewModel.budgetProgress > 0.9
                                    ? [.red, .orange]
                                    : [Color(red: 0.3, green: 0.2, blue: 0.5), Color(red: 0.5, green: 0.35, blue: 0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, min(geometry.size.width, geometry.size.width * viewModel.budgetProgress)), height: 10)
                        .animation(.spring(response: 0.5), value: viewModel.budgetProgress)
                }
            }
            .frame(height: 10)
            
            HStack {
                Text("$\(String(format: "%.2f", viewModel.totalRegistryValue))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let budget = viewModel.budget {
                    Text("$\(String(format: "%.2f", budget))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }

    // MARK: - Notifications Banner

    var notificationsBanner: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.wsAccent)
                    Text("Gift Updates")
                        .font(WSFont.subheading(14))
                        .foregroundStyle(Color.wsNavy)
                    if registryRepo.unreadNotificationCount > 0 {
                        Text("\(registryRepo.unreadNotificationCount)")
                            .font(WSFont.label(10))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.wsAccent)
                            .clipShape(Capsule())
                    }
                }
                Spacer()
                Button("Mark all read") {
                    withAnimation(WSAnimation.spring) {
                        registryRepo.markAllNotificationsRead()
                    }
                }
                .font(WSFont.caption(12))
                .foregroundStyle(Color.wsTextSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider().opacity(0.12)

            ForEach(registryRepo.notifications.prefix(3)) { notification in
                HStack(spacing: 10) {
                    Circle()
                        .fill(notification.isRead ? Color.clear : Color.wsAccent)
                        .frame(width: 7, height: 7)
                    Text(notification.message)
                        .font(WSFont.body(13))
                        .foregroundStyle(notification.isRead ? Color.wsTextSecondary : Color.wsNavy)
                        .lineLimit(1)
                    Spacer()
                    Text(notification.timestamp, style: .relative)
                        .font(WSFont.caption(11))
                        .foregroundStyle(Color.wsMuted)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                if notification.id != registryRepo.notifications.prefix(3).last?.id {
                    Divider().opacity(0.08).padding(.horizontal, 14)
                }
            }
        }
        .background(WSCardBackground(cornerRadius: 14))
        .animation(WSAnimation.spring, value: registryRepo.notifications.count)
    }

    // MARK: - Guest Preview Button

    var guestPreviewButton: some View {
        Button {
            showGuestView = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.wsAccent.opacity(0.9), Color(red: 0.62, green: 0.44, blue: 0.30)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    Image(systemName: "person.fill.viewfinder")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Preview Guest View")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("See how guests experience your registry")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.wsAccent.opacity(0.12), radius: 6, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.wsAccent.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Collaboration Hub
    
    var collaborationDashboardCard: some View {
        VStack(spacing: 16) {
            // User Switcher Header
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(WSGradient.accent)
                        .font(.system(size: 14, weight: .bold))
                    Text("Collaborator Hub")
                        .font(WSFont.subheading(15))
                        .foregroundStyle(Color.wsNavy)
                }
                Text("Co-author lists and manage gifts together in real-time.")
                    .font(WSFont.caption(12))
                    .foregroundStyle(Color.wsTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider().opacity(0.1)
            
            // Switch User Buttons
            HStack(spacing: 12) {
                // User 1 Button
                userSwitchButton(
                    user: RegistryRepository.mockUser1,
                    color: Color(red: 0.35, green: 0.25, blue: 0.55)
                )
                
                // User 2 Button
                userSwitchButton(
                    user: RegistryRepository.mockUser2,
                    color: Color(red: 0.62, green: 0.44, blue: 0.30)
                )
            }
            
            // Room Actions
            VStack(spacing: 12) {
                if viewModel.hasRegistry {
                    // Show our room code to invite others
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("YOUR ROOM CODE")
                                .font(WSFont.label(9))
                                .tracking(1)
                                .foregroundStyle(Color.wsTextSecondary)
                            Text(registryRepo.shareCode)
                                .font(WSFont.subheading(16))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.wsNavy)
                                .tracking(1.5)
                        }
                        
                        Spacer()
                        
                        Button {
                            UIPasteboard.general.string = registryRepo.shareCode
                            joinStatusMessage = "Code Copied!"
                            joinSuccess = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                joinStatusMessage = nil
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc.fill")
                                    .font(.caption)
                                Text("Copy")
                                    .font(WSFont.caption(12))
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(Color.wsNavy)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.wsBackground)
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(Color.wsBorder, lineWidth: 1))
                        }
                    }
                    .padding(12)
                    .background(Color.wsBackground.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Input to join another room
                VStack(alignment: .leading, spacing: 8) {
                    Text("JOIN A COLLABORATION ROOM")
                        .font(WSFont.label(9))
                        .tracking(1)
                        .foregroundStyle(Color.wsTextSecondary)
                    
                    HStack(spacing: 10) {
                        TextField("Enter 8-digit Room Code", text: $roomCodeInput)
                            .font(WSFont.body(14))
                            .padding(.horizontal, 12)
                            .frame(height: 42)
                            .background(Color.wsBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.wsBorder, lineWidth: 1))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                        
                        Button {
                            guard !roomCodeInput.isEmpty else { return }
                            withAnimation(WSAnimation.spring) {
                                let success = registryRepo.joinRegistry(by: roomCodeInput)
                                if success {
                                    joinStatusMessage = "Successfully Joined Room!"
                                    joinSuccess = true
                                    roomCodeInput = ""
                                    showRegistryDetail = true // open the joined registry instantly!
                                } else {
                                    joinStatusMessage = "Invalid Room Code!"
                                    joinSuccess = false
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation { joinStatusMessage = nil }
                            }
                        } label: {
                            Text("Join")
                                .font(WSFont.subheading(14))
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(width: 70, height: 42)
                                .background(WSGradient.button)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(roomCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
                if let message = joinStatusMessage {
                    HStack(spacing: 6) {
                        Image(systemName: joinSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(joinSuccess ? Color.wsSuccess : Color.wsAccent)
                        Text(message)
                            .font(WSFont.caption(12))
                            .fontWeight(.medium)
                            .foregroundStyle(joinSuccess ? Color.wsSuccess : Color.wsAccent)
                        Spacer()
                    }
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(16)
        .background(WSCardBackground(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.wsNavy.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
    
    private func userSwitchButton(user: RegistryRepository.MockUser, color: Color) -> some View {
        let isSelected = registryRepo.currentUser.id == user.id
        
        return Button {
            withAnimation(WSAnimation.spring) {
                registryRepo.switchUser(to: user)
                showRegistryDetail = false
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isSelected ? color : Color.wsMuted)
                
                Text(user.id == "user1" ? "Alex (User 1)" : "Taylor (User 2)")
                    .font(WSFont.caption(13))
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundStyle(isSelected ? Color.wsNavy : Color.wsTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(isSelected ? color.opacity(0.08) : Color.wsBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? color.opacity(0.4) : Color.wsBorder, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}


// MARK: - Reason Card

private struct RegistryReasonCard: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(WSFont.subheading(13))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(WSGradient.button)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(WSFont.subheading(15))
                    .foregroundStyle(Color.wsNavy)

                Text(description)
                    .font(WSFont.body(13))
                    .foregroundStyle(Color.wsTextSecondary)
            }
        }
        .padding(14)
        .wsCard(cornerRadius: 14)
    }
}
