//
//  WSHackathonAppApp.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import SwiftUI

@main
struct WSHackathonAppApp: App {
     @StateObject private var registryRepo = RegistryRepository()
     @StateObject private var cartRepo = CartRepository()
     @StateObject private var wishlistRepo = WishlistRepository()
     @StateObject private var tabBarVM = WSTabBarViewModel()

    var body: some Scene {
        WindowGroup {
            WSTabView()
                .environmentObject(registryRepo)
                .environmentObject(cartRepo)
                .environmentObject(wishlistRepo)
                .environmentObject(tabBarVM)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    /// Handles wshackathon://registry/{CODE} deep links.
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "wshackathon",
              url.host == "registry" else { return }
        // The path is "/{CODE}", drop the leading slash
        let code = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !code.isEmpty else { return }

        // Find the registry whose shareCode matches
        if let registry = registryRepo.registries.first(where: {
            String($0.id.uuidString.prefix(8)).uppercased() == code.uppercased()
        }) {
            registryRepo.selectRegistry(registry.id)
        }
        // Navigate to Registry tab and trigger guest view
        tabBarVM.selectTab(.registry)
        registryRepo.pendingGuestViewCode = code
    }
}
