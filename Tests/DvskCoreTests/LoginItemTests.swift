import XCTest
@testable import DvskCore

final class LoginItemTests: XCTestCase {
    /// Stands in for macOS: counts the calls, and lets a test change the status the way System Settings would.
    private final class FakeService: LoginItemService {
        var status: LoginItemStatus
        var statusAfterRegister = LoginItemStatus.enabled
        var registerError: Error?
        var unregisterError: Error?
        private(set) var registerCalls = 0
        private(set) var unregisterCalls = 0

        init(_ status: LoginItemStatus) {
            self.status = status
        }

        func register() throws {
            registerCalls += 1
            if let registerError { throw registerError }
            status = statusAfterRegister
        }

        func unregister() throws {
            unregisterCalls += 1
            if let unregisterError { throw unregisterError }
            status = .notRegistered
        }
    }

    private struct Refusal: LocalizedError {
        var errorDescription: String? { "Operation not permitted" }
    }

    // MARK: Reading the system's state

    func testReadsEachSystemStatusAsAnOptionState() {
        let expected: [(LoginItemStatus, LoginItemState)] = [
            (.enabled, .on),
            (.notRegistered, .off),
            (.requiresApproval, .needsApproval),
            (.notFound, .notAvailable)
        ]
        for (status, state) in expected {
            XCTAssertEqual(LoginItem(service: FakeService(status)).state, state, "\(status)")
        }
    }

    func testReadingNeverRegistersOrUnregisters() {
        // A fresh install, an update from 0.1.x, a launch and every menu open only read the state.
        for status in [LoginItemStatus.notRegistered, .enabled, .requiresApproval, .notFound] {
            let service = FakeService(status)
            let item = LoginItem(service: service)
            for _ in 0..<3 { _ = item.state }
            XCTAssertEqual(service.registerCalls, 0, "\(status)")
            XCTAssertEqual(service.unregisterCalls, 0, "\(status)")
        }
    }

    func testStateFollowsSystemSettingsAndIsNeverRemembered() {
        let service = FakeService(.enabled)
        let item = LoginItem(service: service)
        XCTAssertEqual(item.state, .on)
        service.status = .requiresApproval // switched off in System Settings
        XCTAssertEqual(item.state, .needsApproval)
        service.status = .enabled // switched on again there
        XCTAssertEqual(item.state, .on)
        service.status = .notRegistered // removed from the list there
        XCTAssertEqual(item.state, .off)
    }

    // MARK: Turning it on and off

    func testTurningOnRegistersOnceAndShowsOn() {
        let service = FakeService(.notRegistered)
        let item = LoginItem(service: service)
        XCTAssertNil(item.setOn(true))
        XCTAssertEqual(item.state, .on)
        XCTAssertNil(item.setOn(true)) // already on: nothing more to ask macOS
        XCTAssertEqual(service.registerCalls, 1)
        XCTAssertEqual(service.unregisterCalls, 0)
    }

    func testTurningOffUnregistersAndShowsOff() {
        let service = FakeService(.enabled)
        let item = LoginItem(service: service)
        XCTAssertNil(item.setOn(false))
        XCTAssertEqual(item.state, .off)
        XCTAssertEqual(service.unregisterCalls, 1)
        XCTAssertEqual(service.registerCalls, 0)
    }

    func testTurningOffRemovesAnEntryThatWaitsForApproval() {
        let service = FakeService(.requiresApproval)
        let item = LoginItem(service: service)
        XCTAssertNil(item.setOn(false))
        XCTAssertEqual(item.state, .off)
        XCTAssertEqual(service.unregisterCalls, 1)
    }

    // MARK: When macOS does not allow it

    func testApprovalNeededAfterTurningOnStaysOffAndSaysWhy() {
        let service = FakeService(.notRegistered)
        service.statusAfterRegister = .requiresApproval
        let item = LoginItem(service: service)
        let message = item.setOn(true)
        XCTAssertEqual(item.state, .needsApproval)
        XCTAssertTrue(message?.contains("System Settings") == true, "\(String(describing: message))")
    }

    func testPendingApprovalIsNotRegisteredAgain() {
        let service = FakeService(.requiresApproval)
        let item = LoginItem(service: service)
        XCTAssertTrue(item.setOn(true)?.contains("System Settings") == true)
        XCTAssertEqual(item.state, .needsApproval)
        XCTAssertEqual(service.registerCalls, 0)
    }

    func testNotFoundIsTriedAndTurnsOnWhenMacOSAccepts() {
        // Some macOS versions report "not found" for an app that was simply never registered.
        let service = FakeService(.notFound)
        let item = LoginItem(service: service)
        XCTAssertEqual(item.state, .notAvailable)
        XCTAssertNil(item.setOn(true))
        XCTAssertEqual(item.state, .on)
        XCTAssertEqual(service.registerCalls, 1)
    }

    func testNotFoundThatMacOSRefusesStaysOffAndSaysWhy() {
        let service = FakeService(.notFound) // for example no app bundle, as under `swift run`
        service.registerError = Refusal()
        let item = LoginItem(service: service)
        let message = item.setOn(true)
        XCTAssertEqual(item.state, .notAvailable)
        XCTAssertNotNil(message)
        XCTAssertEqual(message, LoginItemState.notAvailable.reason)
        XCTAssertEqual(service.registerCalls, 1)
    }

    func testNotFoundThatStaysNotFoundAfterRegisteringStaysOffAndSaysWhy() {
        let service = FakeService(.notFound)
        service.statusAfterRegister = .notFound // the call returns, but nothing was added
        let item = LoginItem(service: service)
        let message = item.setOn(true)
        XCTAssertEqual(item.state, .notAvailable)
        XCTAssertNotNil(message)
        XCTAssertEqual(message, LoginItemState.notAvailable.reason)
        XCTAssertEqual(service.registerCalls, 1)
    }

    func testRefusedRegistrationStaysOffAndReportsTheSystemsReason() {
        let service = FakeService(.notRegistered)
        service.registerError = Refusal()
        let item = LoginItem(service: service)
        let message = item.setOn(true)
        XCTAssertEqual(item.state, .off)
        XCTAssertTrue(message?.contains("Operation not permitted") == true, "\(String(describing: message))")
    }

    func testRefusedRemovalStaysOnAndReportsTheSystemsReason() {
        let service = FakeService(.enabled)
        service.unregisterError = Refusal()
        let item = LoginItem(service: service)
        let message = item.setOn(false)
        XCTAssertEqual(item.state, .on)
        XCTAssertTrue(message?.contains("Operation not permitted") == true, "\(String(describing: message))")
    }

    func testRefusedRemovalOfAPendingEntryDoesNotAskToSwitchItOn() {
        let service = FakeService(.requiresApproval)
        service.unregisterError = Refusal()
        let item = LoginItem(service: service)
        let message = item.setOn(false)
        XCTAssertEqual(item.state, .needsApproval)
        XCTAssertTrue(message?.contains("Operation not permitted") == true, "\(String(describing: message))")
        XCTAssertFalse(message?.contains("switch Dvsk on") == true)
    }
}
