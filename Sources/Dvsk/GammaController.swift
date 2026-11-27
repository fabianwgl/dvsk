import CoreGraphics
import DvskCore

/// Writes per-display gamma tables by composing Dvsk's tint on top of each display's current
/// transfer table via `GammaComposer`. External color-table software dimmers (e.g. BetterDisplay,
/// MonitorControl, Lunar) and live ColorSync profile changes are preserved rather than overwritten.
final class GammaController {
    private static let capacity: UInt32 = 256
    private var composer = GammaComposer<CGDirectDisplayID>()

    init() {
        // A previous crashed run may have left a tint behind; never capture that as a base table.
        CGDisplayRestoreColorSyncSettings()
        refreshDisplays()
    }

    private func displayList(_ get: (UInt32, UnsafeMutablePointer<CGDirectDisplayID>?, UnsafeMutablePointer<UInt32>) -> CGError) -> [CGDirectDisplayID]? {
        var count: UInt32 = 0
        guard get(0, nil, &count) == .success else { return nil }
        guard count > 0 else { return [] }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard get(count, &ids, &count) == .success else { return nil }
        return Array(ids.prefix(Int(count)))
    }

    /// Displays that can show an image now. Leaves out sleeping and hardware-mirrored displays.
    private func activeDisplays() -> [CGDirectDisplayID] {
        displayList { CGGetActiveDisplayList($0, $1, $2) } ?? []
    }

    /// Displays that are connected, including sleeping and mirrored ones. `nil` when unreadable.
    private func onlineDisplays() -> [CGDirectDisplayID]? {
        displayList { CGGetOnlineDisplayList($0, $1, $2) }
    }

    /// Forgets state for unplugged displays. Displays that are only asleep or mirrored keep their
    /// state, and a failed or empty display list changes nothing.
    func refreshDisplays() {
        guard let online = onlineDisplays() else { return }
        composer.prune(keeping: Set(online))
    }

    /// True while some display may still show Dvsk's tint after a return to neutral.
    var hasPendingRestore: Bool { composer.hasPendingRestore }

    private func capture(_ display: CGDirectDisplayID) -> GammaTable? {
        var red = [CGGammaValue](repeating: 0, count: Int(Self.capacity))
        var green = red
        var blue = red
        var samples: UInt32 = 0
        guard CGGetDisplayTransferByTable(display, Self.capacity, &red, &green, &blue, &samples) == .success,
              samples > 0 else { return nil }
        let n = Int(samples)
        return GammaTable(red: Array(red.prefix(n)),
                          green: Array(green.prefix(n)),
                          blue: Array(blue.prefix(n)))
    }

    private func write(_ table: GammaTable, to display: CGDirectDisplayID) -> Bool {
        var red = table.red
        var green = table.green
        var blue = table.blue
        return CGSetDisplayTransferByTable(display, UInt32(table.count), &red, &green, &blue) == .success
    }

    /// Syncs every active display, and every display that may still show Dvsk's tint, to `rgb`.
    /// Writes only when a display's table differs from what Dvsk expects (or when `force` is true).
    /// Returns false when some display could not be read or written.
    @discardableResult
    func sync(_ rgb: RGB, force: Bool = false) -> Bool {
        var ok = true
        let ids = Set(activeDisplays()).union(composer.trackedDisplays)
        for id in ids {
            guard let live = capture(id) else {
                if composer.trackedDisplays.contains(id) { ok = false }
                continue
            }
            guard let desired = composer.plan(display: id, liveTable: live, target: rgb, force: force) else {
                continue
            }
            if write(desired, to: id) {
                composer.didWrite(desired, to: id)
            } else {
                ok = false
            }
        }
        return ok
    }

    /// Restores each display's underlying base table (preserving active software dimming).
    /// Used at quit, when there is no later poll to retry: if any tinted display cannot be read or
    /// written, falls back to `CGDisplayRestoreColorSyncSettings()` so no tint is left behind.
    func restore() {
        if !sync(.neutral, force: true) {
            CGDisplayRestoreColorSyncSettings()
            composer.resetAll()
        }
    }
}
