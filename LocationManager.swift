//
//  LocationManager.swift
//  StaffingAgencyApp
//
//  Created by Harshith Kalluri on 3/17/26.
//

import Foundation
import Combine
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted, .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.first
        manager.stopUpdatingLocation()
    }
    
    // Calculate distance to agency
    func distance(to location: AgencyLocation) -> String? {
        guard let userLoc = userLocation else { return nil }
        let agencyLoc = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let distance = userLoc.distance(from: agencyLoc) / 1609.34 // Convert to miles
        return String(format: "%.1f mi", distance)
    }
}
