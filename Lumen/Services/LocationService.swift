import Foundation
import CoreLocation
import SwiftUI
import Observation

// MARK: - Location Service

@Observable
@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate {
    
    var currentLocation: CLLocationCoordinate2D?
    var isAtHome: Bool = false
    var wasAtHome: Bool = false
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var distanceToHome: Double?
    var lastGeofenceEvent: GeofenceEvent?

    // Gates first-check event emission so launching at home doesn't fire a
    // spurious "arrival" before the user has actually moved.
    private var hasCompletedFirstCheck = false

    private let locationManager = CLLocationManager()
    private let homeRadiusMeter: Double = 100 // 100m radius around home
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 50 // Update every 50 meters
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Public Methods
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startMonitoringLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopMonitoringLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func updateHomeCoordinates(latitude: Double, longitude: Double) {
        // Store in app state or user defaults
        UserDefaults.standard.set(latitude, forKey: "homeLatitude")
        UserDefaults.standard.set(longitude, forKey: "homeLongitude")
        checkIfAtHome()
    }
    
    func getHomeCoordinates() -> (latitude: Double, longitude: Double)? {
        let lat = UserDefaults.standard.double(forKey: "homeLatitude")
        let lon = UserDefaults.standard.double(forKey: "homeLongitude")
        guard lat != 0 && lon != 0 else { return nil }
        return (lat, lon)
    }
    
    // MARK: - Private Methods
    
    private func checkIfAtHome() {
        guard let currentLoc = currentLocation,
              let homeCoords = getHomeCoordinates() else {
            isAtHome = false
            distanceToHome = nil
            return
        }
        
        let homeLoc = CLLocationCoordinate2D(latitude: homeCoords.latitude, longitude: homeCoords.longitude)
        let distance = calculateDistance(from: currentLoc, to: homeLoc)
        distanceToHome = distance
        let newIsAtHome = distance <= homeRadiusMeter

        if hasCompletedFirstCheck {
            if wasAtHome && !newIsAtHome {
                lastGeofenceEvent = GeofenceEvent(type: .departure, timestamp: Date())
            } else if !wasAtHome && newIsAtHome {
                lastGeofenceEvent = GeofenceEvent(type: .arrival, timestamp: Date())
            }
        }

        isAtHome = newIsAtHome
        wasAtHome = newIsAtHome
        hasCompletedFirstCheck = true
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
            default:
                manager.stopUpdatingLocation()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        
        Task { @MainActor in
            self.currentLocation = latest.coordinate
            self.checkIfAtHome()
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
