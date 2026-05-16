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
    
    // MARK: - Metadata
    let brand: String?
    let material: String?
    let productType: String?
    let pattern: String?
    let collection: String?
    let allProductTypes: String?

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
    
    init(id: String, title: String, price: Double?, path: String?,
         availability: String = "ON_HAND", freeShip: Bool? = nil,
         productType: String? = nil, pattern: String? = nil,
         collection: String? = nil, brand: String? = nil,
         material: String? = nil, allProductTypes: String? = nil) {
        self.id = id
        self.title = title
        self.price = price
        self.path = path
        self.availability = availability
        self.freeShip = freeShip
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
        
        // Metadata
        self.productType = dto.properties?.productType
        self.pattern = dto.properties?.pattern
        self.collection = dto.properties?.collection
        self.brand = dto.properties?.brand
        self.material = dto.properties?.material
        self.allProductTypes = dto.properties?.allProductTypes
    }
}
