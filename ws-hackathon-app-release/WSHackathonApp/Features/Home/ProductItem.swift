//
//  ProductItem.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 05/04/26.
//

import Foundation
struct ProductItem: Identifiable {
    let id: String
    let title: String
    let price: Double?
    let path: String?
    
    var imageURL: URL? {
        if let imageUrl = path {
            // First try network URL
            if let networkURL = URL(string: AppConstants.API.imageBasePath + imageUrl) {
                return networkURL
            }
        }
        return nil
    }

    var localImageName: String? {
        guard let path = path else { return nil }
        // Clean path (remove leading slash if present)
        let cleanedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return cleanedPath
    }
}

extension ProductItem {
    init(from dto: ProductItemDTO) {
        self.id = dto.id
        self.title = dto.name
        
        // Price formatting: use regularPrice if available
        if let priceValue = dto.price?.regularPrice {
            self.price = priceValue
        } else {
            self.price = 0.0
        }
        
        // Image: first ProductImage path if available
        if let firstImage = dto.media?.images?.first?.path {
            self.path = firstImage
        } else {
            self.path = nil
        }
    }
}
