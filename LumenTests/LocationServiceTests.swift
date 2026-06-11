import XCTest
import CoreLocation
@testable import Lumen

// LocationService exposes `currentLocation` as a `var`, so we can drive the
// at-home / geofence logic directly without relying on CLLocationManager
// delegate callbacks (which won't fire in a unit-test process).
@MainActor
final class LocationServiceTests: XCTestCase {

    private var service: LocationService!

    private static let latKey = "homeLatitude"
    private static let lonKey = "homeLongitude"

    override func setUp() async throws {
        UserDefaults.standard.removeObject(forKey: Self.latKey)
        UserDefaults.standard.removeObject(forKey: Self.lonKey)
        service = LocationService()
    }

    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: Self.latKey)
        UserDefaults.standard.removeObject(forKey: Self.lonKey)
        service = nil
    }

    // NYC reference point — coords pulled to keep numbers human-readable.
    private let homeLat = 40.7128
    private let homeLon = -74.0060

    private func setLocation(latOffset: Double = 0, lonOffset: Double = 0) {
        service.currentLocation = CLLocationCoordinate2D(
            latitude: homeLat + latOffset,
            longitude: homeLon + lonOffset
        )
    }

    private func applyHomeCoords() {
        service.updateHomeCoordinates(latitude: homeLat, longitude: homeLon)
    }

    // ~0.0004° lon ≈ ~34 m at NYC latitude — well inside 100 m radius.
    // ~0.005° lon ≈ ~420 m — well outside.

    // MARK: - At-home detection

    func testAtHomeWhenWithinRadius() {
        setLocation(lonOffset: 0.0004)
        applyHomeCoords()

        XCTAssertTrue(service.isAtHome)
        let distance = try? XCTUnwrap(service.distanceToHome)
        XCTAssertNotNil(distance)
        XCTAssertLessThan(distance!, 100)
    }

    func testAwayWhenOutsideRadius() throws {
        setLocation(lonOffset: 0.005)
        applyHomeCoords()

        XCTAssertFalse(service.isAtHome)
        let distance = try XCTUnwrap(service.distanceToHome)
        XCTAssertGreaterThan(distance, 100)
    }

    // MARK: - Geofence event publishing

    func testArrivalEventFiresOnInwardCrossing() {
        // Start away — first call sets wasAtHome=false and isAtHome=false, no event.
        setLocation(lonOffset: 0.005)
        applyHomeCoords()
        XCTAssertNil(service.lastGeofenceEvent)

        // Move inside the radius.
        setLocation(lonOffset: 0.0004)
        applyHomeCoords()

        XCTAssertTrue(service.isAtHome)
        XCTAssertEqual(service.lastGeofenceEvent?.type, .arrival)
    }

    func testDepartureEventFiresOnOutwardCrossing() {
        // Start at home — first call fires an arrival event (wasAtHome=false → true).
        setLocation(lonOffset: 0.0004)
        applyHomeCoords()
        XCTAssertTrue(service.isAtHome)
        // Clear the arrival so the assertion below is unambiguous.
        service.lastGeofenceEvent = nil

        // Move outside the radius.
        setLocation(lonOffset: 0.005)
        applyHomeCoords()

        XCTAssertFalse(service.isAtHome)
        XCTAssertEqual(service.lastGeofenceEvent?.type, .departure)
    }

    func testFirstCheckAtHomeDoesNotFireSpuriousArrival() {
        // Launching the app while already inside the home radius used to fire an
        // arrival event because `wasAtHome` defaulted to false. After the fix,
        // the first check just records state without emitting.
        setLocation(lonOffset: 0.0004)
        applyHomeCoords()

        XCTAssertTrue(service.isAtHome)
        XCTAssertNil(service.lastGeofenceEvent)
    }

    func testNoEventWhenStateUnchanged() {
        // Two consecutive "at home" reads should not re-fire arrival.
        setLocation(lonOffset: 0.0004)
        applyHomeCoords()
        service.lastGeofenceEvent = nil

        setLocation(lonOffset: 0.0003)
        applyHomeCoords()

        XCTAssertNil(service.lastGeofenceEvent)
    }
}
