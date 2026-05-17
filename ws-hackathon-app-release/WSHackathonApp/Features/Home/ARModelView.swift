//
//  ARModelView.swift
//  WSHackathonApp
//
//  Created on 17/05/26.
//

import SwiftUI

struct ARModelView: UIViewControllerRepresentable {
    let modelName: String
    let productTitle: String
    
    func makeUIViewController(context: Context) -> ARViewController {
        ARViewController(modelName: modelName, productTitle: productTitle)
    }
    
    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {}
}
