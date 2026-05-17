//
//  RegistryView.swift
//  WSHackathonApp
//

import SwiftUI

enum RegistryRoute: Hashable {
    case create
    case success
    case smartRegistry
    case join
}

struct RegistryView: View {
    @StateObject private var viewModel = RegistryViewModel()
    @EnvironmentObject var registryRepo: RegistryRepository
    @EnvironmentObject var cartRepo: CartRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    
    @State private var showRegistryDetail = false
    @State private var showShareSheet = false
    @State private var showCreateJoinOptions = false
    @State private var registryToPreview: Registry? = nil
    @State private var showInlineTitle = false
    
    private let rowInsets = EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20)
    
    var body: some View {
        ZStack {
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
            .navigationTitle(showRegistryDetail ? (showInlineTitle ? viewModel.displayTitle : "") : AppStrings.Registry.title)
            .navigationBarTitleDisplayMode(showRegistryDetail ? .inline : .large)
            .coordinateSpace(name: "registryScroll")
            .onPreferenceChange(LargeTitleVisibilityKey.self) { isVisible in
                withAnimation(.easeInOut(duration: 0.2)) {
                    showInlineTitle = !isVisible
                }
            }
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
                                withAnimation(WSAnimation.spring) {
                                    showCreateJoinOptions = true
                                }
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
                case .join:
                    JoinRegistryView()
                }
            }
        }
        .onAppear {
            viewModel.bind(repository: registryRepo)
        }
        .onChange(of: registryRepo.pendingGuestViewCode) { _, code in
            if code != nil {
                registryToPreview = registryRepo.currentRegistry
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
        .fullScreenCover(item: $registryToPreview) { registry in
            GuestRegistryView(registry: registry)
                .environmentObject(registryRepo)
        }

        if showCreateJoinOptions {
            customOptionsPopup
        }
    }
}
}

// MARK: - Components
private extension RegistryView {
    
    @ViewBuilder
    var registryContent: some View {
        VStack(spacing: 0) {
            // MARK: - Custom large title (wraps to 2 lines, scrolls away like native large title)
            Text(viewModel.displayTitle)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.wsNavy)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 8)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: LargeTitleVisibilityKey.self,
                            value: geo.frame(in: .named("registryScroll")).maxY > 44
                        )
                    }
                )

            // MARK: - Notifications Banner
            if !registryRepo.notifications.isEmpty {
                notificationsBanner
                    .padding(.top, 4)
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
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(registry.date.formatted(date: .abbreviated, time: .omitted))
                            .font(WSFont.caption(12))
                            .foregroundStyle(Color.wsAccent)
                            .fontWeight(.medium)
                        
                        Text(registry.displayName)
                            .font(WSFont.subheading(20))
                            .foregroundStyle(Color.wsNavy)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("ROOM CODE")
                            .font(WSFont.label(9))
                            .tracking(1)
                            .foregroundStyle(Color.wsTextSecondary)
                        
                        HStack(spacing: 5) {
                            Text(String(registry.id.uuidString.prefix(8)).uppercased())
                                .font(WSFont.subheading(14))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.wsNavy)
                            
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.wsAccent)
                                .onTapGesture {
                                    let code = String(registry.id.uuidString.prefix(8)).uppercased()
                                    UIPasteboard.general.string = code
                                }
                        }
                    }
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
            registryToPreview = registryRepo.currentRegistry
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

                CollaborationFacepileView()
                    .padding(.trailing, 4)

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

    private var customOptionsPopup: some View {
        ZStack {
            // Semi-transparent blurred backdrop
            Color.black.opacity(0.15)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(WSAnimation.spring) {
                        showCreateJoinOptions = false
                    }
                }
            
            Color.clear
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(WSAnimation.spring) {
                        showCreateJoinOptions = false
                    }
                }

            // Popup Card
            VStack(spacing: 20) {
                // Title
                VStack(spacing: 4) {
                    Text("REGISTRY OPTIONS")
                        .font(WSFont.label(11))
                        .tracking(2)
                        .foregroundStyle(Color.wsAccent)
                    
                    Text("Manage Your Registries")
                        .font(WSFont.heading(18))
                        .foregroundStyle(Color.wsNavy)
                }
                .padding(.top, 8)
                
                Divider()
                    .opacity(0.15)
                
                // Actions
                VStack(spacing: 12) {
                    // Create Registry Button
                    Button {
                        withAnimation(WSAnimation.spring) {
                            showCreateJoinOptions = false
                        }
                        tabBarVM.registryPath.append(.create)
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 15))
                            Text("Create a New Registry")
                                .font(WSFont.body(14))
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(WSGradient.button)
                        .clipShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // Join Registry Button
                    Button {
                        withAnimation(WSAnimation.spring) {
                            showCreateJoinOptions = false
                        }
                        tabBarVM.registryPath.append(.join)
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.plus.fill")
                                .font(.system(size: 14))
                            Text("Join an Existing Registry")
                                .font(WSFont.body(14))
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(Color.wsNavy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.wsSurface)
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(Color.wsBorder, lineWidth: 1)
                        )
                        .clipShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                
                // Cancel Action
                Button {
                    withAnimation(WSAnimation.spring) {
                        showCreateJoinOptions = false
                    }
                } label: {
                    Text("Cancel")
                        .font(WSFont.caption(13))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.wsTextSecondary)
                        .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .frame(width: 310)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.wsBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.wsAccent.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 10)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
        .ignoresSafeArea()
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

// MARK: - Preference Key for large title visibility

private struct LargeTitleVisibilityKey: PreferenceKey {
    static var defaultValue: Bool = true
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}
