//
//  WSTabView.swift
//  WSHackathonApp
//

import SwiftUI

struct WSTabView: View {
    @EnvironmentObject var viewModel: WSTabBarViewModel
    @EnvironmentObject var cartRepository: CartRepository
    @EnvironmentObject var registryRepository: RegistryRepository

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            ForEach(viewModel.tabs, id: \.rawValue) { tab in
                view(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: viewModel.selectedTab == tab ? tab.iconFilled : tab.icon)
                    }
                    .tag(tab)
                    .badge(tab == .cart && viewModel.cartItemCount > 0 ? viewModel.cartItemCount : 0)
            }
        }
        .tint(.wsCharcoal)
        .toolbarBackground(.visible, for: .tabBar)
        .background(Color.wsBackground.ignoresSafeArea())
    }

    @ViewBuilder
    private func view(for tab: TabItem) -> some View {
        switch tab {
        case .home:     HomeView()
        case .registry: RegistryView()
        case .cart:     CartView()
        }
    }
}
