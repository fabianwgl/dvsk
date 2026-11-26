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

    private func activeDisplays() -> [CGDirectDisplayID] {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else { return [] }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetActiveDisplayList(count, &ids, &count) == .success else { return [] }
        return Array(ids.prefix(Int(count)))
    }

    /// Forgets state for unplugged displays.
    func refreshDisplays() {
        composer.prune(keeping: Set(activeDisplays()))
    }

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

    /// Syncs every active display to `rgb`, writing only when the display's table differs from
    /// what Dvsk expects (or when `force` is true).
    func sync(_ rgb: RGB, force: Bool = false) {
        let active = activeDisplays()
        composer.prune(keeping: Set(active))
        for id in active {
            guard let live = capture(id),
                  let desired = composer.sync(display: id, liveTable: live, target: rgb, force: force) else {
                continue
            }
            var red = desired.red
            var green = desired.green
            var blue = desired.blue
            CGSetDisplayTransferByTable(id, UInt32(desired.count), &red, &green, &blue)
        }
    }

    /// Restores each display's underlying base table (preserving active software dimming).
    func restore() {
        sync(.neutral)
    }
}
