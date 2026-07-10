import Foundation
import HomeKit

// MARK: - Pre-built sensor streams passed into HomeKitDevice at discovery time.

struct HomeKitDeviceStreams: Sendable {
    let motion: AsyncStream<Bool>?
    let contact: AsyncStream<ContactState>?
}

extension HomeKitDeviceStreams {
    static let empty = HomeKitDeviceStreams(motion: nil, contact: nil)
}
