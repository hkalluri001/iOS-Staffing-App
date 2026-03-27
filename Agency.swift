//
//  Agency.swift
//  StaffingAgencyApp
//
//  Created by Harshith Kalluri on 3/17/26.
//

import Foundation
import CoreLocation

struct Agency: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let logoURL: String?
    let rating: Double
    let reviewCount: Int
    let specialties: [String]
    let description: String
    let website: String
    let phone: String
    let email: String
    let foundedYear: Int
    let employeeCount: String
    let isVerified: Bool
    let locations: [AgencyLocation]
    
    var averageRating: String {
        String(format: "%.1f", rating)
    }
    
    var displaySpecialties: String {
        specialties.prefix(3).joined(separator: " • ")
    }
}

struct AgencyLocation: Codable, Hashable, Identifiable {
    let id = UUID()
    let address: String
    let city: String
    let state: String
    let zipCode: String
    let latitude: Double
    let longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var fullAddress: String {
        "\(address), \(city), \(state) \(zipCode)"
    }
}
