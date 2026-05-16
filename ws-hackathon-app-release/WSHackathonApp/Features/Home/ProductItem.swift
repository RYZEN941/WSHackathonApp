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
    
    // MARK: - Metadata for AI recommendations
    let productType: String?
    let pattern: String?
    let collection: String?
    let brand: String?
    let material: String?
    let allProductTypes: String?
    
    init(id: String, title: String, price: Double?, path: String?,
         productType: String? = nil, pattern: String? = nil,
         collection: String? = nil, brand: String? = nil,
         material: String? = nil, allProductTypes: String? = nil) {
        self.id = id
        self.title = title
        self.price = price
        self.path = path
        self.productType = productType
        self.pattern = pattern
        self.collection = collection
        self.brand = brand
        self.material = material
        self.allProductTypes = allProductTypes
    }
    
    var imageURL: URL? {
        if let imageUrl = path {
            return URL(string: AppConstants.API.imageBasePath + imageUrl)
        }
        return nil
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
        
        // Metadata for AI recommendations
        self.productType = dto.properties?.productType
        self.pattern = dto.properties?.pattern
        self.collection = dto.properties?.collection
        self.brand = dto.properties?.brand
        self.material = dto.properties?.material
        self.allProductTypes = dto.properties?.allProductTypes
    }
}
