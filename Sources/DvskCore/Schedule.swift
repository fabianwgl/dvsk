import Foundation

/// A wall-clock time of day (no date, no time zone).
public struct TimeOfDay: Equatable, Sendable {
    public var hour: Int
    public var minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    public var minutesSinceMidnight: Int { hour * 60 + minute }
}

/// How Dvsk schedules warm colours across the day.
public enum ScheduleMode: String, Equatable, Sendable {
    /// Two-phase fixed clock times (`nightStart` to `nightEnd`).
    case fixed
    /// Three-phase circadian curve combining local sunrise/sunset with `wakeTime` bedtime.
    case circadian
}

/// Active phase of the schedule at a given moment.
public enum SchedulePhase: Equatable, Sendable {
    case daytime
    case sunset
    case bedtime

    public var label: String {
        switch self {
        case .daytime: return "day"
        case .sunset: return "sunset"
        case .bedtime: return "bedtime"
        }
    }
}

/// One sampled point along a 24-hour schedule curve (for UI graphing).
public struct CurveSample: Equatable, Sendable {
    /// Minutes after the curve's start anchor (0...1440).
    public var offsetMinutes: Double
    /// Wall-clock minutes since midnight (0..<1440).
    public var minuteOfDay: Double
    /// Target colour temperature in Kelvin.
    public var kelvin: Double
    /// Dominant phase at this point.
    public var phase: SchedulePhase

    public init(offsetMinutes: Double, minuteOfDay: Double, kelvin: Double, phase: SchedulePhase) {
        self.offsetMinutes = offsetMinutes
        self.minuteOfDay = minuteOfDay
        self.kelvin = kelvin
        self.phase = phase
    }
}

/// Schedule supporting either fixed clock times (default) or a 3-phase circadian curve
/// combining solar sunrise/sunset with a wake-time-anchored bedtime window.
public struct Schedule: Equatable, Sendable {
    public var mode: ScheduleMode
    public var nightStart: TimeOfDay
    public var nightEnd: TimeOfDay
    public var transitionMinutes: Int
    public var dayKelvin: Double
    /// Night temperature in fixed mode; Sunset temperature in circadian mode.
    public var nightKelvin: Double
    /// Deepest night temperature in circadian mode.
    public var bedtimeKelvin: Double
    /// Earliest wake-up time for circadian mode; bedtime begins `bedtimeHoursBeforeWake` earlier.
    public var wakeTime: TimeOfDay
    /// Hours before `wakeTime` when bedtime mode begins (default 9, matching circadian norms).
    public var bedtimeHoursBeforeWake: Double
    /// Manual location for sunrise/sunset calculation (degrees).
    public var latitude: Double
    public var longitude: Double

    public init(mode: ScheduleMode = .fixed,
                nightStart: TimeOfDay = TimeOfDay(hour: 20, minute: 0),
                nightEnd: TimeOfDay = TimeOfDay(hour: 7, minute: 0),
                transitionMinutes: Int = 30,
                dayKelvin: Double = 6500,
                nightKelvin: Double = 2700,
                bedtimeKelvin: Double = 1900,
                wakeTime: TimeOfDay = TimeOfDay(hour: 7, minute: 0),
                bedtimeHoursBeforeWake: Double = 9,
                latitude: Double = 51.5074,
                longitude: Double = -0.1278) {
        self.mode = mode
        self.nightStart = nightStart
        self.nightEnd = nightEnd
        self.transitionMinutes = transitionMinutes
        self.dayKelvin = dayKelvin
        self.nightKelvin = nightKelvin
        self.bedtimeKelvin = bedtimeKelvin
        self.wakeTime = wakeTime
        self.bedtimeHoursBeforeWake = bedtimeHoursBeforeWake
        self.latitude = latitude
        self.longitude = longitude
    }

    private static let minutesPerDay = 1440.0

    /// Solar times for `date` at the configured location.
    public func solarTimes(for date: Date, calendar: Calendar = .current) -> SolarTimes {
        SolarCalculator.times(for: date, latitude: latitude, longitude: longitude, calendar: calendar)
    }

    /// Bedtime start in minutes since midnight (0..<1440).
    public var bedtimeStartMinutes: Double {
        Self.wrapMinutes(Double(wakeTime.minutesSinceMidnight) - bedtimeHoursBeforeWake * 60.0)
    }

    /// 0 = full day, 1 = full night (or sunset/bedtime in circadian mode).
    public func nightWeight(at date: Date, calendar: Calendar = .current) -> Double {
        let now = Self.minutesSinceMidnight(of: date, calendar: calendar)
        switch mode {
        case .fixed:
            return Self.windowWeight(now: now,
                                     start: Double(nightStart.minutesSinceMidnight),
                                     end: Double(nightEnd.minutesSinceMidnight),
                                     fade: Double(max(0, transitionMinutes)),
                                     smooth: false)
        case .circadian:
            let solar = solarTimes(for: date, calendar: calendar)
            let weights = circadianWeights(now: now, solar: solar)
            return max(weights.solarNight, weights.bedtime)
        }
    }

    /// Active phase at `date`.
    public func phase(at date: Date, calendar: Calendar = .current) -> SchedulePhase {
        let now = Self.minutesSinceMidnight(of: date, calendar: calendar)
        switch mode {
        case .fixed:
            return nightWeight(at: date, calendar: calendar) >= 0.5 ? .sunset : .daytime
        case .circadian:
            let solar = solarTimes(for: date, calendar: calendar)
            let weights = circadianWeights(now: now, solar: solar)
            if weights.bedtime >= 0.5 { return .bedtime }
            if weights.solarNight >= 0.5 { return .sunset }
            return .daytime
        }
    }

    public func targetKelvin(at date: Date, calendar: Calendar = .current) -> Double {
        let now = Self.minutesSinceMidnight(of: date, calendar: calendar)
        switch mode {
        case .fixed:
            let weight = Self.windowWeight(now: now,
                                           start: Double(nightStart.minutesSinceMidnight),
                                           end: Double(nightEnd.minutesSinceMidnight),
                                           fade: Double(max(0, transitionMinutes)),
                                           smooth: false)
            return dayKelvin + (nightKelvin - dayKelvin) * weight
        case .circadian:
            let solar = solarTimes(for: date, calendar: calendar)
            return circadianKelvin(now: now, solar: solar)
        }
    }

    /// Samples the 24-hour curve starting at `wakeTime` (circadian) or `00:00` (fixed).
    public func dailyCurve(on date: Date, calendar: Calendar = .current, steps: Int = 144) -> [CurveSample] {
        let clampedSteps = max(24, steps)
        let solar = solarTimes(for: date, calendar: calendar)
        let anchor = mode == .circadian ? Double(wakeTime.minutesSinceMidnight) : 0.0

        return (0...clampedSteps).map { i in
            let offset = Self.minutesPerDay * Double(i) / Double(clampedSteps)
            let minute = Self.wrapMinutes(anchor + offset)
            let kelvin: Double
            let phase: SchedulePhase
            switch mode {
            case .fixed:
                let w = Self.windowWeight(now: minute,
                                          start: Double(nightStart.minutesSinceMidnight),
                                          end: Double(nightEnd.minutesSinceMidnight),
                                          fade: Double(max(0, transitionMinutes)),
                                          smooth: false)
                kelvin = dayKelvin + (nightKelvin - dayKelvin) * w
                phase = w >= 0.5 ? .sunset : .daytime
            case .circadian:
                let w = circadianWeights(now: minute, solar: solar)
                let solarKelvin = dayKelvin + (nightKelvin - dayKelvin) * w.solarNight
                kelvin = solarKelvin + (bedtimeKelvin - solarKelvin) * w.bedtime
                if w.bedtime >= 0.5 {
                    phase = .bedtime
                } else if w.solarNight >= 0.5 {
                    phase = .sunset
                } else {
                    phase = .daytime
                }
            }
            return CurveSample(offsetMinutes: offset, minuteOfDay: minute, kelvin: kelvin, phase: phase)
        }
    }

    // MARK: - Internal helpers

    private func circadianWeights(now: Double, solar: SolarTimes) -> (solarNight: Double, bedtime: Double) {
        let fade = Double(max(0, transitionMinutes))

        let solarNight: Double
        if solar.isPolarDay {
            solarNight = 0
        } else if solar.isPolarNight {
            solarNight = 1
        } else if let sunrise = solar.sunriseMinutes, let sunset = solar.sunsetMinutes {
            solarNight = Self.windowWeight(now: now, start: sunset, end: sunrise, fade: fade, smooth: true)
        } else {
            solarNight = 0
        }

        let wakeMin = Double(wakeTime.minutesSinceMidnight)
        let bedStart = bedtimeStartMinutes
        let bedtime: Double
        if bedtimeHoursBeforeWake <= 0 {
            bedtime = 0
        } else if bedtimeHoursBeforeWake >= 24 {
            bedtime = 1
        } else {
            bedtime = Self.windowWeight(now: now, start: bedStart, end: wakeMin, fade: fade, smooth: true)
        }

        return (solarNight, bedtime)
    }

    private func circadianKelvin(now: Double, solar: SolarTimes) -> Double {
        let weights = circadianWeights(now: now, solar: solar)
        let solarKelvin = dayKelvin + (nightKelvin - dayKelvin) * weights.solarNight
        return solarKelvin + (bedtimeKelvin - solarKelvin) * weights.bedtime
    }

    private static func minutesSinceMidnight(of date: Date, calendar: Calendar) -> Double {
        let parts = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
        return Double(parts.hour ?? 0) * 60
            + Double(parts.minute ?? 0)
            + Double(parts.second ?? 0) / 60
            + Double(parts.nanosecond ?? 0) / 60e9
    }

    private static func windowWeight(now: Double, start: Double, end: Double, fade: Double, smooth: Bool) -> Double {
        guard start != end else { return 0 }

        let inside = start < end ? (now >= start && now < end) : (now >= start || now < end)
        guard fade > 0 else { return inside ? 1 : 0 }

        let half = fade / 2
        let sinceStart = circularDifference(now - start)
        let sinceEnd = circularDifference(now - end)
        let nearStart = abs(sinceStart) < half
        let nearEnd = abs(sinceEnd) < half

        let rawUp = (sinceStart + half) / fade
        let rawDown = 1 - (sinceEnd + half) / fade
        let rampUp = smooth ? smoothstep(rawUp) : rawUp
        let rampDown = smooth ? smoothstep(rawDown) : rawDown

        switch (nearStart, nearEnd) {
        case (true, true): return min(rampUp, rampDown)
        case (true, false): return rampUp
        case (false, true): return rampDown
        case (false, false): return inside ? 1 : 0
        }
    }

    private static func smoothstep(_ x: Double) -> Double {
        let t = min(max(x, 0), 1)
        return t * t * (3 - 2 * t)
    }

    /// Wraps a minute difference into [-720, 720).
    private static func circularDifference(_ difference: Double) -> Double {
        let half = minutesPerDay / 2
        var wrapped = (difference + half).truncatingRemainder(dividingBy: minutesPerDay)
        if wrapped < 0 { wrapped += minutesPerDay }
        return wrapped - half
    }

    private static func wrapMinutes(_ minutes: Double) -> Double {
        let mod = minutes.truncatingRemainder(dividingBy: minutesPerDay)
        return mod < 0 ? mod + minutesPerDay : mod
    }
}
