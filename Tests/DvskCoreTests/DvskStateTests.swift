import XCTest
@testable import DvskCore

final class DvskStateTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func date(_ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: hour, minute: minute))!
    }

    func testDefaultStateAtNoonIsNeutralScheduled() {
        let result = DvskState().resolve(at: date(12), calendar: calendar)
        XCTAssertEqual(result.mode, .scheduled)
        XCTAssertEqual(result.rgb, RGB.neutral)
        XCTAssertEqual(result.kelvin ?? 0, 6500, accuracy: 0.5)
    }

    func testScheduledAtNightUsesNightTemperature() {
        let result = DvskState().resolve(at: date(23), calendar: calendar)
        XCTAssertEqual(result.mode, .scheduled)
        XCTAssertEqual(result.kelvin ?? 0, 2700, accuracy: 0.5)
        let expected = ColorTemperature.rgb(kelvin: 2700)
        XCTAssertEqual(result.rgb.red, expected.red, accuracy: 0.001)
        XCTAssertEqual(result.rgb.green, expected.green, accuracy: 0.001)
        XCTAssertEqual(result.rgb.blue, expected.blue, accuracy: 0.001)
    }

    func testDisabledIsNeutralEvenAtNight() {
        var state = DvskState()
        state.isEnabled = false
        let result = state.resolve(at: date(23), calendar: calendar)
        XCTAssertEqual(result.mode, .disabled)
        XCTAssertEqual(result.rgb, RGB.neutral)
        XCTAssertNil(result.kelvin)
    }

    func testDisabledBeatsDarkroomAndPause() {
        var state = DvskState()
        state.isEnabled = false
        state.isDarkroom = true
        state.pausedUntil = date(23)
        let result = state.resolve(at: date(22), calendar: calendar)
        XCTAssertEqual(result.mode, .disabled)
        XCTAssertEqual(result.rgb, RGB.neutral)
    }

    func testPausedUntilFutureIsNeutral() {
        var state = DvskState()
        state.pausedUntil = date(23, 30)
        let result = state.resolve(at: date(23), calendar: calendar)
        XCTAssertEqual(result.mode, .paused)
        XCTAssertEqual(result.rgb, RGB.neutral)
    }

    func testPausedBeatsDarkroom() {
        var state = DvskState()
        state.isDarkroom = true
        state.pausedUntil = date(23, 30)
        let result = state.resolve(at: date(23), calendar: calendar)
        XCTAssertEqual(result.mode, .paused)
        XCTAssertEqual(result.rgb, RGB.neutral)
    }

    func testExpiredPauseResumesSchedule() {
        var state = DvskState()
        state.pausedUntil = date(22)
        let result = state.resolve(at: date(23), calendar: calendar)
        XCTAssertEqual(result.mode, .scheduled)
        XCTAssertEqual(result.kelvin ?? 0, 2700, accuracy: 0.5)
    }

    func testPauseEndingExactlyNowIsExpired() {
        var state = DvskState()
        state.pausedUntil = date(23)
        XCTAssertEqual(state.resolve(at: date(23), calendar: calendar).mode, .scheduled)
    }

    func testDarkroomIsRedAtDefaultBrightness() {
        var state = DvskState()
        state.isDarkroom = true
        let result = state.resolve(at: date(12), calendar: calendar)
        XCTAssertEqual(result.mode, .darkroom)
        XCTAssertEqual(result.rgb, RGB(red: 0.7, green: 0, blue: 0))
        XCTAssertNil(result.kelvin)
    }

    func testDarkroomBrightnessIsConfigurable() {
        var state = DvskState()
        state.isDarkroom = true
        state.darkroomBrightness = 0.4
        XCTAssertEqual(state.resolve(at: date(12), calendar: calendar).rgb,
                       RGB(red: 0.4, green: 0, blue: 0))
    }

    func testDarkroomBrightnessIsClampedToUnitRange() {
        var state = DvskState()
        state.isDarkroom = true
        state.darkroomBrightness = 3
        XCTAssertEqual(state.resolve(at: date(12), calendar: calendar).rgb,
                       RGB(red: 1, green: 0, blue: 0))
        state.darkroomBrightness = -1
        XCTAssertEqual(state.resolve(at: date(12), calendar: calendar).rgb,
                       RGB(red: 0, green: 0, blue: 0))
    }
}
