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
            if imageUrl.hasPrefix("http") {
                return URL(string: imageUrl)
            }
            return URL(string: AppConstants.API.imageBasePath + imageUrl)
        }
        return nil
    }
    
    var localImageName: String? {
        guard let path = path else { return nil }
        let cleanedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return cleanedPath
    }
    
    var usdzModelName: String? {
        let typeStr = productType?.lowercased() ?? ""
        let titleStr = title.lowercased()
        
        if typeStr.contains("waffle") || titleStr.contains("waffle") {
            return "waffle_maker"
        }
        if typeStr.contains("pasta") || titleStr.contains("pasta") {
            return "pasta_maker"
        }
        if typeStr.contains("espresso") || titleStr.contains("espresso") {
            return "espresso_machine"
        }
        if typeStr.contains("coffee") || titleStr.contains("coffee") {
            return "coffee_maker"
        }
        if typeStr.contains("processor") || titleStr.contains("processor") {
            return "food_processor"
        }
        if typeStr.contains("ice cream") || titleStr.contains("ice cream") || typeStr.contains("ice-cream") || titleStr.contains("ice-cream") {
            return "ice_cream_maker"
        }
        if typeStr.contains("rice") || titleStr.contains("rice") {
            return "rice_cooker"
        }
        if typeStr.contains("frother") || titleStr.contains("frother") {
            return "milk_frother"
        }
        if typeStr.contains("juicer") || titleStr.contains("juicer") || typeStr.contains("juic") || titleStr.contains("juic") {
            return "fruit_juicer"
        }
        
        return nil
    }
}

extension ProductItem {
    static let allMocks: [ProductItem] = [
        ProductItem(
            id: "2505456",
            title: "Williams Sonoma End-Grain Cutting Board, Acacia",
            price: 129.95,
            path: "https://images.unsplash.com/photo-1594756114149-aa32364affc9?auto=format&fit=crop&q=80&w=600&h=600",
            availability: "ON_HAND",
            productType: "cutting-boards-storage",
            pattern: "cutlery",
            brand: "williams-sonoma",
            material: "acacia",
            allProductTypes: "cutting-boards-storage"
        ),
        ProductItem(
            id: "6121370",
            title: "Williams Sonoma Board Oil",
            price: 10.95,
            path: "https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?auto=format&fit=crop&q=80&w=600&h=600",
            availability: "ON_HAND",
            productType: "cutting-board-oil",
            pattern: "homekeeping",
            brand: "williams-sonoma",
            allProductTypes: "cutting-board-oil"
        ),
        ProductItem(
            id: "6247040",
            title: "Hold Everything Lidded Ceramic Bowl, Ashwood",
            price: 89.95,
            path: "https://images.unsplash.com/photo-1610701596007-11502861dcfa?auto=format&fit=crop&q=80&w=600&h=600",
            availability: "ON_HAND",
            productType: "tabletop-serveware-bowl",
            pattern: "homekeeping",
            collection: "[he-pantry, he-fridge]",
            brand: "hold-everything",
            allProductTypes: "tabletop-serveware-bowl"
        ),
        ProductItem(
            id: "1341411",
            title: "Apilco Tradition Porcelain Cup & Saucer",
            price: 34.95,
            path: "https://images.unsplash.com/photo-1517256064527-09c53b2d0bc6?auto=format&fit=crop&q=80&w=600&h=600",
            availability: "ON_HAND",
            productType: "cups-and-saucers",
            pattern: "[tabletop, glassware]",
            collection: "apilco-tradition",
            brand: "apilco",
            allProductTypes: "[cups-and-saucers, tea-cups]"
        ),
        ProductItem(
            id: "2453926",
            title: "Staub Enameled Cast Iron Round Dutch Oven",
            price: 299.95,
            path: "https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?auto=format&fit=crop&q=80&w=600&h=600",
            availability: "ON_HAND",
            productType: "dutch-ovens",
            pattern: "cookware",
            collection: "staub-cast-iron",
            brand: "staub",
            allProductTypes: "dutch-ovens"
        ),
        ProductItem(
            id: "8381456",
            title: "Cuisinart PerfecTemp Coffee Maker, 14-cup",
            price: 119.95,
            path: "https://images.unsplash.com/photo-1572119363156-e21226a2ee4f?auto=format&fit=crop&q=80&w=600&h=600",
            availability: "ON_HAND",
            productType: "coffee-maker",
            pattern: "electrics",
            collection: "cuisinart-coffee",
            brand: "cuisinart",
            allProductTypes: "coffee-maker"
        ),
        ProductItem(
            id: "8227593",
            title: "Hold Everything Lazy Susan, Walnut, 10\"",
            price: 59.95,
            path: "https://images.unsplash.com/photo-1590794056226-79ef3a8147e1?auto=format&fit=crop&q=80&w=600&h=600",
            availability: "ON_HAND",
            productType: "lazy-susan",
            pattern: "homekeeping",
            collection: "he-countertop",
            brand: "hold-everything",
            allProductTypes: "lazy-susan"
        ),
        ProductItem(
            id: "5001660",
            title: "Williams Sonoma Organic House Extra Virgin Olive Oil",
            price: 38.95,
            path: "https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&q=80&w=600&h=600",
            availability: "ON_HAND",
            productType: "oil",
            pattern: "food",
            brand: "williams-sonoma",
            allProductTypes: "oil"
        ),
        ProductItem(
            id: "9670912",
            title: "Dorset Martini Glasses, Set of 4",
            price: 179.80,
            path: "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?auto=format&fit=crop&q=80&w=600&h=600",
            availability: "ON_HAND",
            productType: "bar-glasses-martini",
            pattern: "[tabletop, glassware]",
            collection: "dorset",
            brand: "williams-sonoma",
            allProductTypes: "bar-glasses-martini"
        ),
        ProductItem(
            id: "181543",
            title: "Staub Enameled Cast Iron Traditional Deep Skillet",
            price: 180.00,
            path: "https://images.unsplash.com/photo-1585325701956-60dd9c8553bc?auto=format&fit=crop&q=80&w=600&h=600",
            availability: "ON_HAND",
            productType: "fry-pans-skillets",
            pattern: "cookware",
            collection: "staub-cast-iron",
            brand: "staub",
            allProductTypes: "fry-pans-skillets"
        )
    ]
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
