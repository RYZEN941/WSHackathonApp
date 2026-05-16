//
//  CartView.swift
//  WSHackathonApp
//

import SwiftUI

struct CartView: View {
    @StateObject private var viewModel = CartViewModel()
    @EnvironmentObject var cartRepository: CartRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isEmptyCart {
                    WSEmptyState(
                        title: "Your Cart is Empty",
                        systemImage: "bag",
                        message: "Add beautiful pieces from our curated collection.",
                        buttonTitle: "Continue Shopping",
                        action: { tabBarVM.selectTab(.home) }
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
                                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                                .listRowBackground(WSCardBackground(cornerRadius: 12))
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
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .wsAppBackground()
                    .safeAreaInset(edge: .bottom) {
                        WSCheckoutBar(
                            totalLabel: AppStrings.Cart.total,
                            totalValue: viewModel.totalPriceText,
                            buttonTitle: AppStrings.Cart.checkoutButton,
                            action: {}
                        )
                    }
                }
            }
            .navigationTitle(AppStrings.Cart.title)
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            Task { viewModel.bind(repository: cartRepository) }
        }
    }
}
