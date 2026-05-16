//
//  RegistryItemRow.swift
//  WSHackathonApp
//

import SwiftUI

struct RegistryItemRow: View {

    @StateObject private var viewModel: RegistryItemRowViewModel

    init(viewModel: RegistryItemRowViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CustomAsyncImage(url: viewModel.imageURL)
                .frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.wsNavy.opacity(0.08), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.title)
                        .font(WSFont.body(14))
                        .foregroundStyle(Color.wsNavy)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(viewModel.priceText)
                        .font(WSFont.price(15))
                        .foregroundStyle(Color.wsAccent)
                }

                HStack(spacing: 8) {
                    WSQuantityStepper(
                        quantity: max(viewModel.quantity, 1),
                        onDecrement: viewModel.decreaseQty,
                        onIncrement: viewModel.increaseQty
                    )

                    Spacer(minLength: 0)

                    Button(action: viewModel.addToCart) {
                        HStack(spacing: 5) {
                            Image(systemName: "cart.badge.plus")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Add")
                                .font(WSFont.caption(12))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(WSGradient.button)
                        .clipShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .layoutPriority(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
        .animation(WSAnimation.spring, value: viewModel.quantity)
    }
}
