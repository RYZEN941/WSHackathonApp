//
//  RegistryEvent.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import Foundation
enum RegistryEvent: String, CaseIterable, Identifiable {
    case birthday = "Birthday"
    case wedding = "Wedding"
    case anniversary = "Anniversary"
    case housewarming = "Housewarming"
    case babyShower = "Baby Shower"
    case festiveGifting = "Festive Gifting"
    
    var id: String { rawValue }
    var title: String { rawValue }
}

