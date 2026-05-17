//
//  AppConstants.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import Foundation
enum AppConstants {
    
    enum API {
        #if targetEnvironment(simulator)
        static let baseURL = "http://localhost:3001"
        #else
        static let baseURL = "http://10.2.4.161:3001"
        #endif
        static let imageBasePath = baseURL + "/images/"
        static let timeout: TimeInterval = 30
    }
}
