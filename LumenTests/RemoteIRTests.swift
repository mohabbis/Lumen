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

    // MARK: - RemoteService.send (HTTP routing)

    func testServiceSendPassesValuesToHTTPTransport() async throws {
        let fake = FakeIRTransport()
        let service = RemoteService(httpTransport: fake)
        let ctx = makeContext()
        let profile = RemoteProfile(name: "TV", bridgeHostname: "192.168.1.50")   // .http default
        ctx.insert(profile)
        let command = IRCommand(name: "Power", irCode: "PWR", irFormat: .nec)
        command.remote = profile
        ctx.insert(command)

        try await service.send(command, using: profile)

        let host = await fake.capturedHost
        XCTAssertEqual(await fake.capturedCode, "PWR")
        XCTAssertEqual(await fake.capturedFormat, .nec)
        XCTAssertEqual(host?.address, "192.168.1.50")
    }

    func testServiceSendWithoutHostnameThrows() async {
        let service = RemoteService(httpTransport: FakeIRTransport())
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
        let fake = FakeIRTransport(error: URLError(.cannotConnectToHost))
        let service = RemoteService(httpTransport: fake)
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

    // MARK: - RemoteService transport routing + learn

    func testServiceRoutesBroadlink() async throws {
        let http = FakeIRTransport()
        let broadlink = FakeLearningTransport()
        let service = RemoteService(httpTransport: http, broadlinkTransport: broadlink)
        let ctx = makeContext()
        let profile = RemoteProfile(name: "TV", bridgeHostname: "192.168.1.50", transportKind: .broadlink)
        ctx.insert(profile)
        let command = IRCommand(name: "Power", irCode: "PWR", irFormat: .broadlink)
        command.remote = profile
        ctx.insert(command)

        try await service.send(command, using: profile)

        XCTAssertTrue(await broadlink.didSend)
        XCTAssertNil(await http.capturedHost)
    }

    func testServiceLearnReturnsCode() async throws {
        let broadlink = FakeLearningTransport(codeToReturn: "LEARNED==")
        let service = RemoteService(httpTransport: FakeIRTransport(), broadlinkTransport: broadlink)
        let ctx = makeContext()
        let profile = RemoteProfile(name: "TV", bridgeHostname: "192.168.1.50", transportKind: .broadlink)
        ctx.insert(profile)

        let code = try await service.learn(using: profile)
        XCTAssertEqual(code, "LEARNED==")
    }

    func testServiceLearnOnHTTPThrowsNotSupported() async {
        let service = RemoteService(httpTransport: FakeIRTransport(), broadlinkTransport: FakeLearningTransport())
        let ctx = makeContext()
        let profile = RemoteProfile(name: "TV", bridgeHostname: "192.168.1.50")   // .http
        ctx.insert(profile)

        do {
            _ = try await service.learn(using: profile)
            XCTFail("expected throw")
        } catch {
            guard case AppError.learningNotSupported = error else {
                return XCTFail("expected learningNotSupported, got \(error)")
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

    func testSetTransportKind() throws {
        let ctx = makeContext()
        let vm = RemoteViewModel(modelContext: ctx)
        let profile = RemoteProfile(name: "TV")
        ctx.insert(profile)

        XCTAssertEqual(profile.transportKind, .http)
        vm.setTransportKind(.broadlink, on: profile)
        XCTAssertEqual(profile.transportKind, .broadlink)
    }
}

// MARK: - Fakes (actors: race-free under strict concurrency)

private actor FakeIRTransport: IRTransport {
    let errorToThrow: (any Error)?
    private(set) var capturedCode: String?
    private(set) var capturedFormat: IRFormat?
    private(set) var capturedHost: IRHost?

    init(error: (any Error)? = nil) { errorToThrow = error }

    func send(code: String, format: IRFormat, to host: IRHost) async throws {
        capturedCode = code
        capturedFormat = format
        capturedHost = host
        if let errorToThrow { throw errorToThrow }
    }
}

private actor FakeLearningTransport: IRLearningTransport {
    let codeToReturn: String
    let sendError: (any Error)?
    private(set) var didSend = false
    private(set) var capturedHost: IRHost?

    init(codeToReturn: String = "LEARNED==", sendError: (any Error)? = nil) {
        self.codeToReturn = codeToReturn
        self.sendError = sendError
    }

    func send(code: String, format: IRFormat, to host: IRHost) async throws {
        didSend = true
        capturedHost = host
        if let sendError { throw sendError }
    }

    func learn(from host: IRHost, timeout: Duration) async throws -> String {
        capturedHost = host
        return codeToReturn
    }
}
