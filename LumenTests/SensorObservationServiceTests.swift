import XCTest
@testable import Lumen

// Coverage for SensorObservationService, which previously had zero tests despite
// being a core intelligence surface. Exercises event recording, the 200-event
// ring-buffer cap, per-capability subscription dedup, targeted/global
// cancellation, and re-subscription after a stream terminates.
@MainActor
final class SensorObservationServiceTests: XCTestCase {

    private func motionDevice(
        id: DeviceID = UUID(),
        room: String? = "Hall"
    ) -> (SensorTestDevice, AsyncStream<Bool>.Continuation) {
        let (stream, continuation) = AsyncStream.makeStream(of: Bool.self)
        let device = SensorTestDevice(
            id: id,
            displayName: "Motion",
            roomName: room,
            capabilities: [FakeMotionCapability(motionStream: stream)]
        )
        return (device, continuation)
    }

    private func contactDevice(
        id: DeviceID = UUID(),
        room: String? = "Door"
    ) -> (SensorTestDevice, AsyncStream<ContactState>.Continuation) {
        let (stream, continuation) = AsyncStream.makeStream(of: ContactState.self)
        let device = SensorTestDevice(
            id: id,
            displayName: "Contact",
            roomName: room,
            capabilities: [FakeContactCapability(contactStream: stream)]
        )
        return (device, continuation)
    }

    // MARK: - Recording

    func testRecordsMotionEvents() async {
        let service = SensorObservationService()
        let (device, continuation) = motionDevice()
        service.beginObserving([device])

        continuation.yield(true)
        await waitUntil { service.recentMotionEvents.count == 1 }

        XCTAssertEqual(service.recentMotionEvents.count, 1)
        XCTAssertEqual(service.recentMotionEvents.first?.motionDetected, true)
        XCTAssertEqual(service.recentMotionEvents.first?.roomName, "Hall")
        continuation.finish()
        service.cancelAll()
    }

    func testRecordsContactEvents() async {
        let service = SensorObservationService()
        let (device, continuation) = contactDevice()
        service.beginObserving([device])

        continuation.yield(.open)
        await waitUntil { service.recentContactEvents.count == 1 }

        XCTAssertEqual(service.recentContactEvents.count, 1)
        XCTAssertEqual(service.recentContactEvents.first?.state, .open)
        XCTAssertEqual(service.recentContactEvents.first?.roomName, "Door")
        continuation.finish()
        service.cancelAll()
    }

    // MARK: - Ring buffer cap

    func testMotionEventsAreCappedAtMax() async {
        let service = SensorObservationService()
        let (device, continuation) = motionDevice()
        service.beginObserving([device])

        for i in 0..<205 { continuation.yield(i % 2 == 0) }

        await waitUntil(timeout: 5) { service.recentMotionEvents.count >= 200 }
        await settle() // let any remaining buffered events drain
        XCTAssertEqual(service.recentMotionEvents.count, 200, "Ring buffer must cap at 200 events")
        continuation.finish()
        service.cancelAll()
    }

    // MARK: - Subscription dedup

    func testReObservingActiveDeviceDoesNotDropItsSubscription() async {
        let service = SensorObservationService()
        let idA = UUID()
        let (deviceA, contA) = motionDevice(id: idA)
        service.beginObserving([deviceA])
        contA.yield(true)
        await waitUntil { service.recentMotionEvents.count == 1 }

        // Re-observe A (already subscribed) alongside a new contact device B.
        let (deviceB, contB) = contactDevice()
        service.beginObserving([deviceA, deviceB])

        contA.yield(false)   // A's original subscription is still live
        contB.yield(.open)   // B is a fresh subscription
        await waitUntil {
            service.recentMotionEvents.count == 2 && service.recentContactEvents.count == 1
        }

        XCTAssertEqual(service.recentMotionEvents.count, 2)
        XCTAssertEqual(service.recentContactEvents.count, 1)
        contA.finish(); contB.finish()
        service.cancelAll()
    }

    // MARK: - Cancellation

    func testCancelObservationsStopsRecordingForDevice() async {
        let service = SensorObservationService()
        let id = UUID()
        let (device, continuation) = motionDevice(id: id)
        service.beginObserving([device])
        continuation.yield(true)
        await waitUntil { service.recentMotionEvents.count == 1 }

        service.cancelObservations(forDeviceIDs: [id])
        continuation.yield(true) // must not be recorded — subscription cancelled
        await settle()

        XCTAssertEqual(service.recentMotionEvents.count, 1)
        service.cancelAll()
    }

    func testCancelAllStopsRecording() async {
        let service = SensorObservationService()
        let (device, continuation) = motionDevice()
        service.beginObserving([device])
        continuation.yield(true)
        await waitUntil { service.recentMotionEvents.count == 1 }

        service.cancelAll()
        continuation.yield(true)
        await settle()

        XCTAssertEqual(service.recentMotionEvents.count, 1)
    }

    // MARK: - Re-subscription after stream termination

    func testResubscribesAfterStreamTerminates() async {
        let service = SensorObservationService()
        let id = UUID()
        let (device1, cont1) = motionDevice(id: id)
        service.beginObserving([device1])
        cont1.yield(true)
        await waitUntil { service.recentMotionEvents.count == 1 }

        cont1.finish()      // stream ends → service deactivates the key
        await settle()

        // Same device ID, fresh stream — the key should be free to re-subscribe.
        let (device2, cont2) = motionDevice(id: id)
        service.beginObserving([device2])
        cont2.yield(true)
        await waitUntil { service.recentMotionEvents.count == 2 }

        XCTAssertEqual(service.recentMotionEvents.count, 2)
        cont2.finish()
        service.cancelAll()
    }
}
