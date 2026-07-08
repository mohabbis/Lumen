import XCTest
import SwiftData
@testable import Lumen

@MainActor
final class RemoteIRTests: XCTestCase {

    private var container: ModelContainer!

    private func makeContext() -> ModelContext {
        let c = PersistenceCoordinator.makeInMemoryContainer()
        container = c
        return c.mainContext
    }

    // MARK: - normalizedEndpoint

    func testNormalizeBareIPPrependsHTTP() throws {
        let url = try HTTPIRTransport.normalizedEndpoint(from: "192.168.1.50")
        XCTAssertEqual(url.absoluteString, "http://192.168.1.50")
    }

    func testNormalizeHostPort() throws {
        let url = try HTTPIRTransport.normalizedEndpoint(from: "blaster.local:8080")
        XCTAssertEqual(url.scheme, "http")
        XCTAssertEqual(url.host, "blaster.local")
        XCTAssertEqual(url.port, 8080)
    }

    func testNormalizePreservesHTTPS() throws {
        let url = try HTTPIRTransport.normalizedEndpoint(from: "https://ir.example.com")
        XCTAssertEqual(url.scheme, "https")
        XCTAssertEqual(url.host, "ir.example.com")
    }

    func testNormalizeTrimsWhitespace() throws {
        let url = try HTTPIRTransport.normalizedEndpoint(from: "  192.168.1.50  ")
        XCTAssertEqual(url.absoluteString, "http://192.168.1.50")
    }

    func testNormalizeEmptyThrowsNotConfigured() {
        XCTAssertThrowsError(try HTTPIRTransport.normalizedEndpoint(from: "   ")) { error in
            guard case AppError.remoteBridgeNotConfigured = error else {
                return XCTFail("expected remoteBridgeNotConfigured, got \(error)")
            }
        }
    }

    func testNormalizeNoHostThrowsInvalid() {
        XCTAssertThrowsError(try HTTPIRTransport.normalizedEndpoint(from: "http://")) { error in
            guard case AppError.invalidBridgeHostname = error else {
                return XCTFail("expected invalidBridgeHostname, got \(error)")
            }
        }
    }

    func testNormalizeWrongSchemeThrowsInvalid() {
        XCTAssertThrowsError(try HTTPIRTransport.normalizedEndpoint(from: "ftp://host")) { error in
            guard case AppError.invalidBridgeHostname = error else {
                return XCTFail("expected invalidBridgeHostname, got \(error)")
            }
        }
    }

    // MARK: - makeRequest

    func testMakeRequestShape() throws {
        let endpoint = try HTTPIRTransport.normalizedEndpoint(from: "192.168.1.50")
        let request = HTTPIRTransport.makeRequest(endpoint: endpoint, code: "ABC123", format: .broadlink)

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "http://192.168.1.50/send")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let body = try XCTUnwrap(request.httpBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
        XCTAssertEqual(json?["code"], "ABC123")
        XCTAssertEqual(json?["format"], "broadlink")
    }

    // MARK: - RemoteService.send

    func testServiceSendPassesValuesToTransport() async throws {
        let fake = FakeIRTransport()
        let service = RemoteService(transport: fake)
        let ctx = makeContext()
        let profile = RemoteProfile(name: "TV", bridgeHostname: "192.168.1.50")
        ctx.insert(profile)
        let command = IRCommand(name: "Power", irCode: "PWR", irFormat: .nec)
        command.remote = profile
        ctx.insert(command)

        try await service.send(command, using: profile)

        XCTAssertEqual(fake.capturedCode, "PWR")
        XCTAssertEqual(fake.capturedFormat, .nec)
        XCTAssertEqual(fake.capturedEndpoint?.absoluteString, "http://192.168.1.50")
    }

    func testServiceSendWithoutHostnameThrows() async {
        let service = RemoteService(transport: FakeIRTransport())
        let ctx = makeContext()
        let profile = RemoteProfile(name: "TV")   // no bridgeHostname
        ctx.insert(profile)
        let command = IRCommand(name: "Power", irCode: "PWR", irFormat: .nec)
        command.remote = profile
        ctx.insert(command)

        do {
            try await service.send(command, using: profile)
            XCTFail("expected throw")
        } catch {
            guard case AppError.remoteBridgeNotConfigured = error else {
                return XCTFail("expected remoteBridgeNotConfigured, got \(error)")
            }
        }
    }

    func testServiceSendWrapsTransportFailure() async {
        let fake = FakeIRTransport()
        fake.errorToThrow = URLError(.cannotConnectToHost)
        let service = RemoteService(transport: fake)
        let ctx = makeContext()
        let profile = RemoteProfile(name: "TV", bridgeHostname: "192.168.1.50")
        ctx.insert(profile)
        let command = IRCommand(name: "Power", irCode: "PWR", irFormat: .nec)
        command.remote = profile
        ctx.insert(command)

        do {
            try await service.send(command, using: profile)
            XCTFail("expected throw")
        } catch {
            guard case AppError.irSendFailed = error else {
                return XCTFail("expected irSendFailed, got \(error)")
            }
        }
    }

    // MARK: - RemoteViewModel CRUD

    func testAddCommandPersists() throws {
        let ctx = makeContext()
        let vm = RemoteViewModel(modelContext: ctx)
        let profile = RemoteProfile(name: "TV")
        ctx.insert(profile)

        vm.addCommand(to: profile, name: "Power", code: "PWR", format: .broadlink)

        XCTAssertEqual(profile.commands.count, 1)
        XCTAssertEqual(profile.commands.first?.name, "Power")
        XCTAssertFalse(vm.isShowingAddCommand)
        XCTAssertNil(vm.error)
    }

    func testDeleteCommand() throws {
        let ctx = makeContext()
        let vm = RemoteViewModel(modelContext: ctx)
        let profile = RemoteProfile(name: "TV")
        ctx.insert(profile)
        vm.addCommand(to: profile, name: "Power", code: "PWR", format: .broadlink)
        let command = try XCTUnwrap(profile.commands.first)

        vm.deleteCommand(command)

        XCTAssertTrue(profile.commands.isEmpty)
        XCTAssertNil(vm.error)
    }

    func testSetBridgeHostnameTrimsAndClears() throws {
        let ctx = makeContext()
        let vm = RemoteViewModel(modelContext: ctx)
        let profile = RemoteProfile(name: "TV")
        ctx.insert(profile)

        vm.setBridgeHostname("  192.168.1.50  ", on: profile)
        XCTAssertEqual(profile.bridgeHostname, "192.168.1.50")

        vm.setBridgeHostname("   ", on: profile)
        XCTAssertNil(profile.bridgeHostname)
    }
}

// MARK: - Fake Transport
// Records the values RemoteService hands it; touched only on the main actor.

private final class FakeIRTransport: IRTransport, @unchecked Sendable {
    var capturedCode: String?
    var capturedFormat: IRFormat?
    var capturedEndpoint: URL?
    var errorToThrow: (any Error)?

    func send(code: String, format: IRFormat, to endpoint: URL) async throws {
        capturedCode = code
        capturedFormat = format
        capturedEndpoint = endpoint
        if let errorToThrow { throw errorToThrow }
    }
}
