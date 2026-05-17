//
//  AppConstants.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import Foundation
enum AppConstants {
    
    enum API {
        // Deployed backend URL for both Simulator and physical iPhone devices
        static let baseURL = "https://wshackathonapp.onrender.com"
        static let imageBasePath = baseURL + "/images/"
        static let timeout: TimeInterval = 30
    }
}
