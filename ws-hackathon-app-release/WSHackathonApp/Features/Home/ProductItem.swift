//
//  ProductItem.swift
//  WSHackathonApp
//

import Foundation

struct ProductItem: Identifiable, Hashable {
    let id: String
    let title: String
    let price: Double?
    let path: String?
    let availability: String
    let freeShip: Bool?
    let brand: String?
    let material: String?

    static func == (lhs: ProductItem, rhs: ProductItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var isInStock: Bool {
        availability.uppercased().contains("ON_HAND")
    }

    var availabilityLabel: String {
        isInStock ? "In Stock" : "Available to Order"
    }

    var editorialDescription: String {
        "An essential from our curated collection — designed for everyday gatherings and moments worth savoring. Timeless form meets lasting quality, exclusively at Williams Sonoma."
    }
    
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
            if let networkURL = URL(string: AppConstants.API.imageBasePath + imageUrl) {
                return networkURL
            }
        }
        return nil
    }
    
    var localImageName: String? {
        guard let path = path else { return nil }
        let cleanedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return cleanedPath
    }
}

extension ProductItem {
    init(from dto: ProductItemDTO) {
        self.id = dto.id
        self.title = dto.name
        self.availability = dto.availability ?? "ON_HAND"
        self.freeShip = dto.freeShip
        self.brand = dto.properties?.brand
        self.material = dto.properties?.material

        if let priceValue = dto.price?.regularPrice {
            self.price = priceValue
        } else {
            self.price = 0.0
        }

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
