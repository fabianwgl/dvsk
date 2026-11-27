import Foundation

/// A per-channel display gamma transfer table with values in 0...1.
public struct GammaTable: Equatable, Sendable {
    public var red: [Float]
    public var green: [Float]
    public var blue: [Float]

    public init(red: [Float], green: [Float], blue: [Float]) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public var count: Int { min(red.count, min(green.count, blue.count)) }
    public var isEmpty: Bool { count == 0 }

    /// Multiplies each channel by the RGB multiplier, clamping into 0...1.
    public func tinted(by rgb: RGB) -> GammaTable {
        let rf = Float(rgb.red)
        let gf = Float(rgb.green)
        let bf = Float(rgb.blue)
        return GammaTable(
            red: red.map { min(max($0 * rf, 0), 1) },
            green: green.map { min(max($0 * gf, 0), 1) },
            blue: blue.map { min(max($0 * bf, 0), 1) }
        )
    }

    /// True when both tables have the same length and every entry is within `tolerance`.
    /// Accounts for hardware LUT quantization (e.g. 8-bit or 10-bit transfer tables).
    public func isApproximatelyEqual(to other: GammaTable, tolerance: Float = 0.005) -> Bool {
        guard red.count == other.red.count,
              green.count == other.green.count,
              blue.count == other.blue.count else { return false }
        for i in 0..<red.count {
            if abs(red[i] - other.red[i]) > tolerance { return false }
            if abs(green[i] - other.green[i]) > tolerance { return false }
            if abs(blue[i] - other.blue[i]) > tolerance { return false }
        }
        return true
    }
}

/// Composes Dvsk's tint on top of each display's current gamma table without compounding
/// and without clobbering external color-table dimmers (e.g. BetterDisplay, MonitorControl, Lunar)
/// or live ColorSync profile changes.
///
/// Usage: call `plan` with the table read back from a display; if it returns a table, write it and
/// call `didWrite` only when the write succeeded. Nothing is recorded as on screen until then, so a
/// failed write is retried on the next `plan` instead of being mistaken for an external change.
///
/// A display has state only while Dvsk's tint may be on it: from the first tint until a readback
/// confirms the base table is back (or another app has replaced the table).
public struct GammaComposer<DisplayID: Hashable> {
    /// The table under Dvsk's tint, restored when returning to neutral.
    private var bases: [DisplayID: GammaTable] = [:]
    /// Tables Dvsk wrote to the display since `bases` was captured, newest last. A live table that
    /// matches any of them is Dvsk's own (including a newer write the display silently dropped).
    private var written: [DisplayID: [GammaTable]] = [:]
    private let historyLimit = 4
    public let tolerance: Float

    public init(tolerance: Float = 0.005) {
        self.tolerance = tolerance
    }

    /// Displays that may still show Dvsk's tint.
    public var trackedDisplays: Set<DisplayID> { Set(written.keys) }

    /// True while a display may still show Dvsk's tint, so a neutral restore is not yet confirmed.
    public var hasPendingRestore: Bool { !written.isEmpty }

    /// Forgets state for displays that are no longer online. An empty list is ignored, since it
    /// usually means the display list could not be read rather than that every display is gone.
    public mutating func prune(keeping onlineIDs: Set<DisplayID>) {
        guard !onlineIDs.isEmpty else { return }
        bases = bases.filter { onlineIDs.contains($0.key) }
        written = written.filter { onlineIDs.contains($0.key) }
    }

    /// Forgets one display.
    public mutating func forget(_ display: DisplayID) {
        bases.removeValue(forKey: display)
        written.removeValue(forKey: display)
    }

    /// Clears all remembered state (for example after a full ColorSync reset).
    public mutating func resetAll() {
        bases.removeAll()
        written.removeAll()
    }

    /// Given the table currently loaded on `display` and the desired `target` RGB multiplier,
    /// returns the table to write to the display, or `nil` when no write is needed.
    /// The returned table is not recorded as on screen until `didWrite` is called.
    ///
    /// - Parameter force: When true, returns the desired table even if `liveTable` already
    ///   matches it (useful right after wake when readback may briefly lag). At neutral it rewrites
    ///   the base table of any display that may still be tinted.
    public mutating func plan(display: DisplayID,
                              liveTable: GammaTable,
                              target: RGB,
                              force: Bool = false) -> GammaTable? {
        guard !liveTable.isEmpty else { return nil }
        let ours = isOurs(liveTable, on: display)

        if target == RGB.neutral {
            guard written[display] != nil, let base = bases[display] else {
                // Dvsk has not tinted this display; leave whatever is on it untouched.
                return nil
            }
            if liveTable.isApproximatelyEqual(to: base, tolerance: tolerance) {
                // Readback confirms the restore.
                forget(display)
                return force ? base : nil
            }
            if ours || force {
                // Our tint is still there (or the restore write was lost): write the base again.
                // State is kept until a readback confirms it.
                return base
            }
            // Another app or macOS already replaced the table; leave it alone.
            forget(display)
            return nil
        }

        if written[display] == nil || !ours {
            // First tint, or an external tool (software dimmer, profile change, wake reset)
            // wrote a new table: that table becomes the base.
            bases[display] = liveTable
            written[display] = []
        }

        guard let base = bases[display] else { return nil }
        let desired = base.tinted(by: target)
        if !force, ours, liveTable.isApproximatelyEqual(to: desired, tolerance: tolerance) {
            // Readback shows the desired table is already on screen.
            record(desired, on: display)
            return nil
        }
        return desired
    }

    /// Records that `table` was successfully written to `display`.
    public mutating func didWrite(_ table: GammaTable, to display: DisplayID) {
        guard written[display] != nil else { return }
        record(table, on: display)
    }

    private func isOurs(_ live: GammaTable, on display: DisplayID) -> Bool {
        written[display]?.contains { live.isApproximatelyEqual(to: $0, tolerance: tolerance) } ?? false
    }

    private mutating func record(_ table: GammaTable, on display: DisplayID) {
        var history = written[display] ?? []
        if history.last != table { history.append(table) }
        if history.count > historyLimit { history.removeFirst(history.count - historyLimit) }
        written[display] = history
    }
}
