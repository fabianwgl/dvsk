import Foundation

/// Sunrise and sunset times for a calendar day at a given latitude and longitude.
public struct SolarTimes: Equatable, Sendable {
    /// Minutes since local midnight (0..<1440), or nil during polar day/night.
    public var sunriseMinutes: Double?
    /// Minutes since local midnight (0..<1440), or nil during polar day/night.
    public var sunsetMinutes: Double?
    /// Total minutes of daylight for the day (0 during polar night, 1440 during polar day).
    public var daylightMinutes: Double
    /// True when the sun remains above the horizon all day.
    public var isPolarDay: Bool
    /// True when the sun remains below the horizon all day.
    public var isPolarNight: Bool

    public init(sunriseMinutes: Double?,
                sunsetMinutes: Double?,
                daylightMinutes: Double,
                isPolarDay: Bool = false,
                isPolarNight: Bool = false) {
        self.sunriseMinutes = sunriseMinutes
        self.sunsetMinutes = sunsetMinutes
        self.daylightMinutes = daylightMinutes
        self.isPolarDay = isPolarDay
        self.isPolarNight = isPolarNight
    }
}

/// Pure-Swift NOAA solar calculator (Jean Meeus astronomical algorithms).
/// Accurate to within ~1 minute for latitudes between 65°S and 65°N, with zero network calls.
public enum SolarCalculator {
    /// Standard official sunrise/sunset zenith angle (90° + 34' refraction + 16' solar radius).
    private static let officialZenithDegrees = 90.833

    public static func times(for date: Date,
                             latitude: Double,
                             longitude: Double,
                             calendar: Calendar = .current) -> SolarTimes {
        let clampedLat = min(max(latitude, -89.9), 89.9)
        let clampedLon = min(max(longitude, -180.0), 180.0)

        let dayParts = calendar.dateComponents([.year, .month, .day], from: date)
        let noonComponents = DateComponents(year: dayParts.year,
                                            month: dayParts.month,
                                            day: dayParts.day,
                                            hour: 12,
                                            minute: 0,
                                            second: 0)
        let localNoon = calendar.date(from: noonComponents) ?? date
        let tzOffsetMinutes = Double(calendar.timeZone.secondsFromGMT(for: localNoon)) / 60.0

        // Julian Day at local noon (1970-01-01 00:00:00 UTC == JD 2440587.5).
        let julianDay = localNoon.timeIntervalSince1970 / 86400.0 + 2440587.5
        let t = (julianDay - 2451545.0) / 36525.0

        let geomMeanLongSun = wrapDegrees(280.46646 + t * (36000.76983 + t * 0.0003032))
        let geomMeanAnomSun = 357.52911 + t * (35999.05029 - 0.0001537 * t)
        let eccentEarthOrbit = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)

        let anomRad = radians(geomMeanAnomSun)
        let sunEqOfCtr = sin(anomRad) * (1.914602 - t * (0.004817 + 0.000014 * t))
            + sin(2 * anomRad) * (0.019993 - 0.000101 * t)
            + sin(3 * anomRad) * 0.000289

        let sunTrueLong = geomMeanLongSun + sunEqOfCtr
        let omega = 125.04 - 1934.136 * t
        let sunAppLong = sunTrueLong - 0.00569 - 0.00478 * sin(radians(omega))

        let meanObliqEcliptic = 23.0 + (26.0 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60.0) / 60.0
        let obliqCorr = meanObliqEcliptic + 0.00256 * cos(radians(omega))

        let declRad = asin(sin(radians(obliqCorr)) * sin(radians(sunAppLong)))

        let varY = pow(tan(radians(obliqCorr / 2.0)), 2)
        let longRad = radians(geomMeanLongSun)
        let eqOfTime = 4.0 * degrees(
            varY * sin(2 * longRad)
            - 2 * eccentEarthOrbit * sin(anomRad)
            + 4 * eccentEarthOrbit * varY * sin(anomRad) * cos(2 * longRad)
            - 0.5 * varY * varY * sin(4 * longRad)
            - 1.25 * eccentEarthOrbit * eccentEarthOrbit * sin(2 * anomRad)
        )

        let latRad = radians(clampedLat)
        let zenithRad = radians(officialZenithDegrees)
        let cosHA = cos(zenithRad) / (cos(latRad) * cos(declRad)) - tan(latRad) * tan(declRad)

        if cosHA > 1.0 {
            return SolarTimes(sunriseMinutes: nil, sunsetMinutes: nil, daylightMinutes: 0,
                              isPolarDay: false, isPolarNight: true)
        }
        if cosHA < -1.0 {
            return SolarTimes(sunriseMinutes: nil, sunsetMinutes: nil, daylightMinutes: 1440,
                              isPolarDay: true, isPolarNight: false)
        }

        let haDegrees = degrees(acos(cosHA))
        let solarNoonMinutes = 720.0 - 4.0 * clampedLon - eqOfTime + tzOffsetMinutes
        let sunrise = wrapMinutes(solarNoonMinutes - 4.0 * haDegrees)
        let sunset = wrapMinutes(solarNoonMinutes + 4.0 * haDegrees)
        let daylight = haDegrees * 8.0

        return SolarTimes(sunriseMinutes: sunrise,
                          sunsetMinutes: sunset,
                          daylightMinutes: daylight)
    }

    private static func radians(_ deg: Double) -> Double { deg * .pi / 180.0 }
    private static func degrees(_ rad: Double) -> Double { rad * 180.0 / .pi }

    private static func wrapDegrees(_ deg: Double) -> Double {
        let mod = deg.truncatingRemainder(dividingBy: 360.0)
        return mod < 0 ? mod + 360.0 : mod
    }

    private static func wrapMinutes(_ minutes: Double) -> Double {
        let mod = minutes.truncatingRemainder(dividingBy: 1440.0)
        return mod < 0 ? mod + 1440.0 : mod
    }
}
