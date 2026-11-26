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
public struct GammaComposer<DisplayID: Hashable> {
    private var bases: [DisplayID: GammaTable] = [:]
    private var lastWritten: [DisplayID: GammaTable] = [:]
    public let tolerance: Float

    public init(tolerance: Float = 0.005) {
        self.tolerance = tolerance
    }

    /// Forgets state for displays that are no longer active.
    public mutating func prune(keeping activeIDs: Set<DisplayID>) {
        bases = bases.filter { activeIDs.contains($0.key) }
        lastWritten = lastWritten.filter { activeIDs.contains($0.key) }
    }

    /// Clears all remembered state (for example after a full ColorSync reset).
    public mutating func resetAll() {
        bases.removeAll()
        lastWritten.removeAll()
    }

    /// Given the table currently loaded on `display` and the desired `target` RGB multiplier,
    /// returns the table to write to the display, or `nil` when no write is needed.
    ///
    /// - Parameter force: When true, returns the desired table even if `liveTable` already
    ///   matches it (useful right after wake when readback may briefly lag).
    public mutating func sync(display: DisplayID,
                              liveTable: GammaTable,
                              target: RGB,
                              force: Bool = false) -> GammaTable? {
        guard !liveTable.isEmpty else { return nil }

        if target == RGB.neutral {
            guard let written = lastWritten.removeValue(forKey: display) else {
                // Already neutral; leave whatever is on the display untouched.
                return nil
            }
            if liveTable.isApproximatelyEqual(to: written, tolerance: tolerance) {
                // Nobody else replaced our tint; restore the preserved base table.
                return bases[display]
            } else {
                // Another app or macOS already replaced the table; adopt it and do not overwrite.
                bases[display] = liveTable
                return nil
            }
        }

        if let written = lastWritten[display] {
            if !liveTable.isApproximatelyEqual(to: written, tolerance: tolerance) {
                // An external tool (software dimmer, profile change, wake reset) wrote a new table.
                bases[display] = liveTable
            }
        } else {
            // Transitioning away from neutral or seeing this display for the first time.
            bases[display] = liveTable
        }

        guard let base = bases[display] else { return nil }
        let desired = base.tinted(by: target)
        let alreadyApplied = lastWritten[display] != nil
            && liveTable.isApproximatelyEqual(to: desired, tolerance: tolerance)

        lastWritten[display] = desired
        if alreadyApplied && !force {
            return nil
        }
        return desired
    }
}
