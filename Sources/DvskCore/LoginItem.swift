import Foundation

/// What macOS reports about Dvsk's own entry in System Settings → General → Login Items & Extensions.
/// Mirrors `SMAppService.Status`, so this file needs no system framework.
public enum LoginItemStatus: Equatable, Sendable {
    /// Never added, or added and removed again.
    case notRegistered
    /// Added, and macOS will start Dvsk at login.
    case enabled
    /// Added, but switched off in System Settings.
    case requiresApproval
    /// macOS cannot find Dvsk as a login item, for example when Dvsk does not run as an app bundle.
    case notFound
}

/// The part of macOS the option talks to. The app wraps `SMAppService`; tests use a fake.
public protocol LoginItemService {
    /// Asked every time, never cached: System Settings can change it behind the app's back.
    var status: LoginItemStatus { get }
    func register() throws
    func unregister() throws
}

/// What the "Launch at login" option shows. Only `.on` is ticked.
public enum LoginItemState: Equatable, Sendable {
    case on
    case off
    /// Dvsk is in the list but switched off there.
    case needsApproval
    /// macOS cannot find Dvsk as a login item, for example under `swift run`.
    case notAvailable

    init(_ status: LoginItemStatus) {
        switch status {
        case .enabled: self = .on
        case .notRegistered: self = .off
        case .requiresApproval: self = .needsApproval
        case .notFound: self = .notAvailable
        }
    }

    /// A short reason for the states where the option cannot simply be turned on.
    public var reason: String? {
        switch self {
        case .on, .off:
            return nil
        case .needsApproval:
            return "macOS needs your approval. In System Settings → General → Login Items & Extensions, switch Dvsk on."
        case .notAvailable:
            return "macOS could not find Dvsk as a login item here. "
                + "Launch at login needs Dvsk to run as the installed app, not from the command line."
        }
    }
}

/// The rules of "Launch at login". It keeps no copy of the state: macOS owns it,
/// and the Login Items list in System Settings can change at any time.
public struct LoginItem {
    private let service: any LoginItemService

    public init(service: any LoginItemService) {
        self.service = service
    }

    /// What macOS says right now. Reading never registers or unregisters anything.
    public var state: LoginItemState {
        LoginItemState(service.status)
    }

    /// Asks macOS to add (`true`) or remove (`false`) Dvsk, only when that is needed. Adding is not tried while the
    /// entry waits for approval. Returns nil when the system's list now matches the request, otherwise a short reason.
    @discardableResult
    public func setOn(_ wantOn: Bool) -> String? {
        var failure: Error?
        switch (wantOn, state) {
        case (true, .off), (true, .notAvailable):
            // "Not found" is tried too: some macOS versions report it for an app that was never registered.
            do { try service.register() } catch { failure = error }
        case (false, .on), (false, .needsApproval):
            do { try service.unregister() } catch { failure = error }
        default:
            break // already as asked, or waiting for approval: register() would only fail as "already registered"
        }

        // The answer comes from macOS's list, not from whether the call threw.
        let after = state
        let done = wantOn ? after == .on : (after == .off || after == .notAvailable)
        if done { return nil }
        if wantOn, let reason = after.reason { return reason }
        if let failure { return "macOS did not allow the change: \(failure.localizedDescription)" }
        return wantOn ? "macOS did not add Dvsk to the Login Items."
                      : "macOS did not remove Dvsk from the Login Items."
    }
}
