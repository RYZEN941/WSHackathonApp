//
//  ScannerViewModel.swift
//  WSHackathonApp
//

import Foundation
import Combine
import UIKit

// MARK: - Scanner State

enum ScannerState: Equatable {
    case idle
    case scanning
    case barcodeDetected
    case labelRecognized
    case objectIdentified(confidence: Float)
    case noMatch
}

// MARK: - ScannerViewModel

@MainActor
final class ScannerViewModel: ObservableObject {

    // Published UI state
    @Published var state: ScannerState = .scanning
    @Published var matchedProduct: ProductItem?
    @Published var confidenceValue: Float = 0

    // Throttle gates
    private var lastOCRTime: Date = .distantPast
    private var lastMLTime:  Date = .distantPast
    private let ocrInterval:  TimeInterval = 0.5
    private let mlInterval:   TimeInterval = 1.0

    // Flag to avoid duplicate navigation after a match fires
    private var didFire = false

    // ─────────────────────────────────────────────
    // MARK: Brand → product-id lookup
    // Keys are lowercased brand strings that might appear in OCR text.
    // Values are ProductItem.id from the mock catalog.
    // ─────────────────────────────────────────────
    let brandMap: [String: String] = [
        "staub"           : "2453926",   // Staub Dutch Oven
        "cuisinart"       : "8381456",   // Cuisinart Coffee Maker
        "apilco"          : "1341411",   // Apilco Cup & Saucer
        "williams-sonoma" : "2505456",   // WS Cutting Board
        "williams sonoma" : "2505456",
        "hold everything" : "8227593",   // Lazy Susan
        "hold-everything" : "8227593"
    ]

    // ─────────────────────────────────────────────
    // MARK: Object label → product-id lookup
    // Keys match MobileNetV2 / Vision classification label substrings
    // ─────────────────────────────────────────────
    let objectMap: [String: String] = [
        "dutch oven"       : "2453926",
        "casserole"        : "2453926",
        "pot"              : "2453926",
        "frying pan"       : "181543",
        "skillet"          : "181543",
        "coffee maker"     : "8381456",
        "coffeemaker"      : "8381456",
        "coffee"           : "8381456",
        "cup"              : "1341411",
        "saucer"           : "1341411",
        "mug"              : "1341411",
        "cutting board"    : "2505456",
        "chopping board"   : "2505456",
        "lazy susan"       : "8227593",
        "turntable"        : "8227593",
        "martini"          : "9670912",
        "wine glass"       : "9670912",
        "glass"            : "9670912",
        "bowl"             : "6247040",
        "ceramic"          : "6247040",
        "olive oil"        : "5001660",
        "bottle"           : "5001660"
    ]

    // ─────────────────────────────────────────────
    // MARK: Catalog (mock products — same set used in ProductItem)
    // ─────────────────────────────────────────────
    let catalog: [ProductItem] = ProductItem.allMocks

    // MARK: - Throttle helpers

    var shouldRunOCR: Bool {
        Date().timeIntervalSince(lastOCRTime) >= ocrInterval
    }

    var shouldRunML: Bool {
        Date().timeIntervalSince(lastMLTime) >= mlInterval
    }

    func markOCRRan()  { lastOCRTime = Date() }
    func markMLRan()   { lastMLTime  = Date() }

    // MARK: - Match handling

    func handleBarcode(_ code: String) {
        guard !didFire else { return }
        if let product = catalog.first(where: { $0.id == code }) {
            fire(product: product, via: .barcodeDetected)
        }
    }

    func handleOCRText(_ text: String) {
        guard !didFire else { return }
        let lower = text.lowercased()
        for (brand, id) in brandMap {
            if lower.contains(brand), let product = catalog.first(where: { $0.id == id }) {
                fire(product: product, via: .labelRecognized)
                return
            }
        }
    }

    func handleMLLabel(_ label: String, confidence: Float) {
        guard !didFire else { return }
        guard confidence >= 0.4 else { return }
        let lower = label.lowercased()
        for (object, id) in objectMap {
            if lower.contains(object), let product = catalog.first(where: { $0.id == id }) {
                fire(product: product, via: .objectIdentified(confidence: confidence))
                return
            }
        }
    }

    // Simulate a scan for demo / fallback button
    func simulateScan() {
        guard !didFire else { return }
        let demoProduct = catalog.first(where: { $0.id == "2453926" }) ?? catalog[0]
        fire(product: demoProduct, via: .objectIdentified(confidence: 0.92))
    }

    func reset() {
        didFire        = false
        matchedProduct = nil
        confidenceValue = 0
        state          = .scanning
        lastOCRTime    = .distantPast
        lastMLTime     = .distantPast
    }

    // MARK: - Private

    private func fire(product: ProductItem, via newState: ScannerState) {
        didFire         = true
        matchedProduct  = product
        if case .objectIdentified(let c) = newState { confidenceValue = c }
        state           = newState
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}
