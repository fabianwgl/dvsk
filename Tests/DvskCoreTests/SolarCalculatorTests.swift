import XCTest
@testable import DvskCore

final class SolarCalculatorTests: XCTestCase {
    private func makeDate(year: Int, month: Int, day: Int, timeZone: String) -> (Date, Calendar) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZone)!
        let date = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
        return (date, calendar)
    }

    func testNovemberParisMatchesExpectedSunriseSunset() {
        // Paris (48.8566°N, 2.3522°E) on Nov 26 (CET = UTC+1): sunrise ~08:16, sunset ~16:59, ~8h43m daylight.
        let (date, cal) = makeDate(year: 2026, month: 11, day: 26, timeZone: "Europe/Paris")
        let times = SolarCalculator.times(for: date, latitude: 48.8566, longitude: 2.3522, calendar: cal)
        XCTAssertFalse(times.isPolarDay)
        XCTAssertFalse(times.isPolarNight)
        XCTAssertEqual(times.sunriseMinutes!, 8 * 60 + 16, accuracy: 4)
        XCTAssertEqual(times.sunsetMinutes!, 16 * 60 + 59, accuracy: 4)
        XCTAssertEqual(times.daylightMinutes, 8 * 60 + 43, accuracy: 6)
    }

    func testSummerNewYorkHandlesDST() {
        // 40.71°N, -74.01°W on June 21 (EDT = UTC-4): sunrise ~05:25, sunset ~20:31.
        let (date, cal) = makeDate(year: 2026, month: 6, day: 21, timeZone: "America/New_York")
        let times = SolarCalculator.times(for: date, latitude: 40.7128, longitude: -74.0060, calendar: cal)
        XCTAssertEqual(times.sunriseMinutes!, 5 * 60 + 25, accuracy: 4)
        XCTAssertEqual(times.sunsetMinutes!, 20 * 60 + 31, accuracy: 4)
    }

    func testPolarDayAndPolarNightInTromso() {
        let (summer, calSummer) = makeDate(year: 2026, month: 6, day: 21, timeZone: "Europe/Oslo")
        let polarDay = SolarCalculator.times(for: summer, latitude: 69.65, longitude: 18.96, calendar: calSummer)
        XCTAssertTrue(polarDay.isPolarDay)
        XCTAssertFalse(polarDay.isPolarNight)
        XCTAssertNil(polarDay.sunriseMinutes)
        XCTAssertNil(polarDay.sunsetMinutes)

        let (winter, calWinter) = makeDate(year: 2026, month: 12, day: 21, timeZone: "Europe/Oslo")
        let polarNight = SolarCalculator.times(for: winter, latitude: 69.65, longitude: 18.96, calendar: calWinter)
        XCTAssertTrue(polarNight.isPolarNight)
        XCTAssertFalse(polarNight.isPolarDay)
        XCTAssertNil(polarNight.sunriseMinutes)
        XCTAssertNil(polarNight.sunsetMinutes)
    }
}
