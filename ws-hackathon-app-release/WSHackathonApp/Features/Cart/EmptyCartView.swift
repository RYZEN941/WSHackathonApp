//
//  EmptyCartView.swift
//  WSHackathonApp
//

import SwiftUI

struct EmptyCartView: View {
    
    var onContinueShopping: (() -> Void)? = nil
    
    var body: some View {
        ContentUnavailableView(
            "Your Cart is Empty",
            systemImage: "cart",
            description: Text("Add some beautiful items from our curated collection.")
        )
    }
}
