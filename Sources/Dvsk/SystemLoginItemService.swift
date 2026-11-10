import Foundation
import ServiceManagement
import DvskCore

/// Dvsk's own entry in System Settings → General → Login Items & Extensions, through `SMAppService`.
/// Thin on purpose: the rules live in `LoginItem` (DvskCore), which has the tests.
struct SystemLoginItemService: LoginItemService {
    private struct NotAnAppBundle: LocalizedError {
        var errorDescription: String? { "Dvsk is not running as an app bundle, so macOS cannot register it." }
    }

    /// macOS can only register an app bundle. Under `swift run` there is none, and
    /// `SMAppService` is not asked anything: status is "not found" and changes are refused.
    private var runsAsAppBundle: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    var status: LoginItemStatus {
        guard runsAsAppBundle else { return .notFound }
        switch SMAppService.mainApp.status {
        case .notRegistered: return .notRegistered
        case .enabled: return .enabled
        case .requiresApproval: return .requiresApproval
        case .notFound: return .notFound
        @unknown default: return .notFound
        }
    }

    func register() throws {
        guard runsAsAppBundle else { throw NotAnAppBundle() }
        try SMAppService.mainApp.register()
    }

    func unregister() throws {
        guard runsAsAppBundle else { throw NotAnAppBundle() }
        try SMAppService.mainApp.unregister()
    }
}
