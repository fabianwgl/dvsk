import XCTest
@testable import DvskCore

final class GammaComposerTests: XCTestCase {
    private func ramp(scale: Float = 1.0, count: Int = 16) -> GammaTable {
        let values = (0..<count).map { Float($0) / Float(count - 1) * scale }
        return GammaTable(red: values, green: values, blue: values)
    }

    /// Plans a sync and, like `GammaController`, records the table as written when there is one.
    @discardableResult
    private func sync(_ composer: inout GammaComposer<UInt32>,
                      display: UInt32 = 1,
                      liveTable: GammaTable,
                      target: RGB,
                      force: Bool = false) -> GammaTable? {
        let table = composer.plan(display: display, liveTable: liveTable, target: target, force: force)
        if let table { composer.didWrite(table, to: display) }
        return table
    }

    func testRepeatedApplyNeverCompounds() {
        var composer = GammaComposer<UInt32>()
        let original = ramp(scale: 1.0)
        let warm = ColorTemperature.rgb(kelvin: 2700)

        let first = sync(&composer, liveTable: original, target: warm)
        XCTAssertNotNil(first)
        XCTAssertEqual(first!.red.last!, Float(warm.red), accuracy: 0.001)
        XCTAssertEqual(first!.blue.last!, Float(warm.blue), accuracy: 0.001)

        // Simulating quantized readback from macOS LUT.
        let quantized = GammaTable(
            red: first!.red.map { ($0 * 255).rounded() / 255 },
            green: first!.green.map { ($0 * 255).rounded() / 255 },
            blue: first!.blue.map { ($0 * 255).rounded() / 255 }
        )
        let second = sync(&composer, liveTable: quantized, target: warm)
        XCTAssertNil(second, "No redundant write when display already matches tinted table")

        // Changing target temperature uses original base, never compounding.
        let warmer = ColorTemperature.rgb(kelvin: 1900)
        let third = sync(&composer, liveTable: quantized, target: warmer)
        XCTAssertNotNil(third)
        XCTAssertEqual(third!.blue.last!, Float(warmer.blue), accuracy: 0.001)
    }

    func testExternalSoftwareDimmingIsPreservedAndTinted() {
        var composer = GammaComposer<UInt32>()
        let full = ramp(scale: 1.0)
        let warm = ColorTemperature.rgb(kelvin: 2700)

        let initial = sync(&composer, liveTable: full, target: warm)!
        XCTAssertEqual(initial.red.last!, 1.0, accuracy: 0.001)

        // BetterDisplay dims to 40% via an untinted gamma table.
        let dimmed = ramp(scale: 0.4)
        let composed = sync(&composer, liveTable: dimmed, target: warm)
        XCTAssertNotNil(composed)
        XCTAssertEqual(composed!.red.last!, Float(0.4 * warm.red), accuracy: 0.001)
        XCTAssertEqual(composed!.green.last!, Float(0.4 * warm.green), accuracy: 0.001)
        XCTAssertEqual(composed!.blue.last!, Float(0.4 * warm.blue), accuracy: 0.001)

        // Next tick with composed table still on display does not re-dim or rewrite.
        XCTAssertNil(sync(&composer, liveTable: composed!, target: warm))

        // Raising brightness back above threshold restores full-scale tinted table.
        let backToFull = sync(&composer, liveTable: full, target: warm)
        XCTAssertNotNil(backToFull)
        XCTAssertEqual(backToFull!.red.last!, Float(warm.red), accuracy: 0.001)
        XCTAssertEqual(backToFull!.blue.last!, Float(warm.blue), accuracy: 0.001)
    }

    func testReturningToNeutralPreservesExternalDimming() {
        var composer = GammaComposer<UInt32>()
        let dimmed = ramp(scale: 0.5)
        let warm = ColorTemperature.rgb(kelvin: 2700)

        // Sunset starts while already dimmed.
        let tinted = sync(&composer, liveTable: dimmed, target: warm)!
        XCTAssertEqual(tinted.red.last!, Float(0.5 * warm.red), accuracy: 0.001)

        // Pausing / disabling Dvsk restores the 50% dimmed base table instead of 100%.
        let restored = sync(&composer, liveTable: tinted, target: .neutral)
        XCTAssertEqual(restored, dimmed)

        // Subsequent neutral ticks do nothing.
        XCTAssertNil(sync(&composer, liveTable: dimmed, target: .neutral))
    }

    func testDimmingToZeroAndRecoveringWorks() {
        var composer = GammaComposer<UInt32>()
        let full = ramp(scale: 1.0)
        let warm = ColorTemperature.rgb(kelvin: 2700)
        _ = sync(&composer, liveTable: full, target: warm)

        // Dimmed all the way to black.
        let black = ramp(scale: 0.0)
        _ = sync(&composer, liveTable: black, target: warm)

        // Raising brightness back up to 20% re-captures base and tints it.
        let dim20 = ramp(scale: 0.2)
        let recovered = sync(&composer, liveTable: dim20, target: warm)
        XCTAssertNotNil(recovered)
        XCTAssertEqual(recovered!.red.last!, Float(0.2 * warm.red), accuracy: 0.001)
        XCTAssertEqual(recovered!.blue.last!, Float(0.2 * warm.blue), accuracy: 0.001)
    }

    // MARK: - Review regressions

    func testFailedTintWriteIsRetriedWithoutCompounding() {
        var composer = GammaComposer<UInt32>()
        let full = ramp()
        let t2700 = ColorTemperature.rgb(kelvin: 2700)
        let t2600 = ColorTemperature.rgb(kelvin: 2600)

        let onScreen = sync(&composer, liveTable: full, target: t2700)!

        // The 2600K write fails: plan without didWrite. The display still shows 2700K.
        _ = composer.plan(display: 1, liveTable: onScreen, target: t2600)

        // Next poll must recompose from the original base, not tint the 2700K table again.
        let retry = composer.plan(display: 1, liveTable: onScreen, target: t2600)!
        XCTAssertEqual(retry.green.last!, Float(t2600.green), accuracy: 0.001)
        XCTAssertEqual(retry.blue.last!, Float(t2600.blue), accuracy: 0.001)
        composer.didWrite(retry, to: 1)

        // Pause restores the untinted base, not the 2700K table.
        XCTAssertEqual(composer.plan(display: 1, liveTable: retry, target: .neutral), full)
    }

    func testSilentlyDroppedWriteIsNotAdoptedAsBase() {
        var composer = GammaComposer<UInt32>()
        let full = ramp()
        let t2700 = ColorTemperature.rgb(kelvin: 2700)
        let t2600 = ColorTemperature.rgb(kelvin: 2600)

        let onScreen = sync(&composer, liveTable: full, target: t2700)!
        // The write reports success but the display keeps showing 2700K.
        _ = sync(&composer, liveTable: onScreen, target: t2600)

        let retry = composer.plan(display: 1, liveTable: onScreen, target: t2600)!
        XCTAssertEqual(retry.blue.last!, Float(t2600.blue), accuracy: 0.001)
    }

    func testFailedNeutralRestoreStaysPendingUntilReadbackMatches() {
        var composer = GammaComposer<UInt32>()
        let full = ramp()
        let warm = ColorTemperature.rgb(kelvin: 2700)
        let tinted = sync(&composer, liveTable: full, target: warm)!

        // The restore write fails: the tint is still on screen and the restore stays pending.
        XCTAssertEqual(composer.plan(display: 1, liveTable: tinted, target: .neutral), full)
        XCTAssertTrue(composer.hasPendingRestore)
        XCTAssertEqual(composer.plan(display: 1, liveTable: tinted, target: .neutral), full)

        // Once a readback shows the base, the restore is confirmed.
        XCTAssertNil(composer.plan(display: 1, liveTable: full, target: .neutral))
        XCTAssertFalse(composer.hasPendingRestore)
    }

    func testForcedNeutralReapplyRewritesBase() {
        var composer = GammaComposer<UInt32>()
        let full = ramp()
        let warm = ColorTemperature.rgb(kelvin: 2700)
        let tinted = sync(&composer, liveTable: full, target: warm)!

        // Right after wake the readback may lag or show something else; a forced re-apply
        // at neutral still puts the base back.
        let lagging = ramp(scale: 0.9)
        XCTAssertEqual(composer.plan(display: 1, liveTable: lagging, target: .neutral, force: true), full)
        XCTAssertEqual(composer.plan(display: 1, liveTable: tinted, target: .neutral, force: true), full)
        XCTAssertTrue(composer.hasPendingRestore)
    }

    func testPruneIgnoresEmptyListAndKeepsListedDisplays() {
        var composer = GammaComposer<UInt32>()
        let full = ramp()
        let warm = ColorTemperature.rgb(kelvin: 2700)
        let tinted = sync(&composer, display: 1, liveTable: full, target: warm)!
        _ = sync(&composer, display: 2, liveTable: full, target: warm)

        composer.prune(keeping: [])
        XCTAssertEqual(composer.trackedDisplays, [1, 2])

        // Display 2 is unplugged; display 1 (online, perhaps asleep) keeps its state.
        composer.prune(keeping: [1])
        XCTAssertEqual(composer.trackedDisplays, [1])

        // Display 1 wakes still showing Dvsk's tint: not tinted twice, and neutral restores the original.
        XCTAssertNil(composer.plan(display: 1, liveTable: tinted, target: warm))
        XCTAssertEqual(composer.plan(display: 1, liveTable: tinted, target: .neutral), full)
    }
}
