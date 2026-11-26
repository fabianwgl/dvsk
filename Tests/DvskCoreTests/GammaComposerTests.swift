import XCTest
@testable import DvskCore

final class GammaComposerTests: XCTestCase {
    private func ramp(scale: Float = 1.0, count: Int = 16) -> GammaTable {
        let values = (0..<count).map { Float($0) / Float(count - 1) * scale }
        return GammaTable(red: values, green: values, blue: values)
    }

    func testRepeatedApplyNeverCompounds() {
        var composer = GammaComposer<UInt32>()
        let original = ramp(scale: 1.0)
        let warm = ColorTemperature.rgb(kelvin: 2700)

        let first = composer.sync(display: 1, liveTable: original, target: warm)
        XCTAssertNotNil(first)
        XCTAssertEqual(first!.red.last!, Float(warm.red), accuracy: 0.001)
        XCTAssertEqual(first!.blue.last!, Float(warm.blue), accuracy: 0.001)

        // Simulating quantized readback from macOS LUT.
        let quantized = GammaTable(
            red: first!.red.map { ($0 * 255).rounded() / 255 },
            green: first!.green.map { ($0 * 255).rounded() / 255 },
            blue: first!.blue.map { ($0 * 255).rounded() / 255 }
        )
        let second = composer.sync(display: 1, liveTable: quantized, target: warm)
        XCTAssertNil(second, "No redundant write when display already matches tinted table")

        // Changing target temperature uses original base, never compounding.
        let warmer = ColorTemperature.rgb(kelvin: 1900)
        let third = composer.sync(display: 1, liveTable: quantized, target: warmer)
        XCTAssertNotNil(third)
        XCTAssertEqual(third!.blue.last!, Float(warmer.blue), accuracy: 0.001)
    }

    func testExternalSoftwareDimmingIsPreservedAndTinted() {
        var composer = GammaComposer<UInt32>()
        let full = ramp(scale: 1.0)
        let warm = ColorTemperature.rgb(kelvin: 2700)

        let initial = composer.sync(display: 1, liveTable: full, target: warm)!
        XCTAssertEqual(initial.red.last!, 1.0, accuracy: 0.001)

        // BetterDisplay dims to 40% via an untinted gamma table.
        let dimmed = ramp(scale: 0.4)
        let composed = composer.sync(display: 1, liveTable: dimmed, target: warm)
        XCTAssertNotNil(composed)
        XCTAssertEqual(composed!.red.last!, Float(0.4 * warm.red), accuracy: 0.001)
        XCTAssertEqual(composed!.green.last!, Float(0.4 * warm.green), accuracy: 0.001)
        XCTAssertEqual(composed!.blue.last!, Float(0.4 * warm.blue), accuracy: 0.001)

        // Next tick with composed table still on display does not re-dim or rewrite.
        XCTAssertNil(composer.sync(display: 1, liveTable: composed!, target: warm))

        // Raising brightness back above threshold restores full-scale tinted table.
        let backToFull = composer.sync(display: 1, liveTable: full, target: warm)
        XCTAssertNotNil(backToFull)
        XCTAssertEqual(backToFull!.red.last!, Float(warm.red), accuracy: 0.001)
        XCTAssertEqual(backToFull!.blue.last!, Float(warm.blue), accuracy: 0.001)
    }

    func testReturningToNeutralPreservesExternalDimming() {
        var composer = GammaComposer<UInt32>()
        let dimmed = ramp(scale: 0.5)
        let warm = ColorTemperature.rgb(kelvin: 2700)

        // Sunset starts while already dimmed.
        let tinted = composer.sync(display: 1, liveTable: dimmed, target: warm)!
        XCTAssertEqual(tinted.red.last!, Float(0.5 * warm.red), accuracy: 0.001)

        // Pausing / disabling Dvsk restores the 50% dimmed base table instead of 100%.
        let restored = composer.sync(display: 1, liveTable: tinted, target: .neutral)
        XCTAssertEqual(restored, dimmed)

        // Subsequent neutral ticks do nothing.
        XCTAssertNil(composer.sync(display: 1, liveTable: dimmed, target: .neutral))
    }

    func testDimmingToZeroAndRecoveringWorks() {
        var composer = GammaComposer<UInt32>()
        let full = ramp(scale: 1.0)
        let warm = ColorTemperature.rgb(kelvin: 2700)
        _ = composer.sync(display: 1, liveTable: full, target: warm)

        // Dimmed all the way to black.
        let black = ramp(scale: 0.0)
        _ = composer.sync(display: 1, liveTable: black, target: warm)

        // Raising brightness back up to 20% re-captures base and tints it.
        let dim20 = ramp(scale: 0.2)
        let recovered = composer.sync(display: 1, liveTable: dim20, target: warm)
        XCTAssertNotNil(recovered)
        XCTAssertEqual(recovered!.red.last!, Float(0.2 * warm.red), accuracy: 0.001)
        XCTAssertEqual(recovered!.blue.last!, Float(0.2 * warm.blue), accuracy: 0.001)
    }
}
