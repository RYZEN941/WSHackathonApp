//
//  CartItemRow.swift
//  WSHackathonApp
//

import SwiftUI

struct CartItemRow: View {
    let item: CartItem
    let onAdd: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            CustomAsyncImage(url: item.imageURL)
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.wsMuted.opacity(0.15), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(WSFont.body(14))
                    .foregroundStyle(Color.wsNavy)
                    .lineLimit(2)

                Text(item.price, format: .currency(code: "USD"))
                    .font(WSFont.price(16))
                    .foregroundStyle(Color.wsNavy)

                WSQuantityStepper(
                    quantity: item.quantity,
                    onDecrement: onRemove,
                    onIncrement: onAdd
                )
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}
