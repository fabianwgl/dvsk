import Foundation
import DvskCore

/// UserDefaults-backed settings. Observable so SwiftUI and the engine react to edits.
final class Preferences: ObservableObject {
    private let defaults: UserDefaults

    @Published var isEnabled: Bool { didSet { defaults.set(isEnabled, forKey: Key.enabled) } }
    @Published var isDarkroom: Bool { didSet { defaults.set(isDarkroom, forKey: Key.darkroom) } }
    @Published var pausedUntil: Date? {
        didSet {
            if let pausedUntil {
                defaults.set(pausedUntil, forKey: Key.pausedUntil)
            } else {
                defaults.removeObject(forKey: Key.pausedUntil)
            }
        }
    }
    @Published var nightStart: TimeOfDay { didSet { defaults.set(nightStart.minutesSinceMidnight, forKey: Key.nightStart) } }
    @Published var nightEnd: TimeOfDay { didSet { defaults.set(nightEnd.minutesSinceMidnight, forKey: Key.nightEnd) } }
    @Published var transitionMinutes: Int { didSet { defaults.set(transitionMinutes, forKey: Key.transition) } }
    @Published var dayKelvin: Double { didSet { defaults.set(dayKelvin, forKey: Key.dayKelvin) } }
    @Published var nightKelvin: Double { didSet { defaults.set(nightKelvin, forKey: Key.nightKelvin) } }
    @Published var darkroomBrightness: Double { didSet { defaults.set(darkroomBrightness, forKey: Key.darkroomBrightness) } }

    private enum Key {
        static let enabled = "enabled"
        static let darkroom = "darkroom"
        static let pausedUntil = "pausedUntil"
        static let nightStart = "nightStartMinutes"
        static let nightEnd = "nightEndMinutes"
        static let transition = "transitionMinutes"
        static let dayKelvin = "dayKelvin"
        static let nightKelvin = "nightKelvin"
        static let darkroomBrightness = "darkroomBrightness"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let fallback = Schedule()

        func timeOfDay(_ key: String, default value: TimeOfDay) -> TimeOfDay {
            guard let minutes = defaults.object(forKey: key) as? Int else { return value }
            let clamped = min(max(minutes, 0), 1439)
            return TimeOfDay(hour: clamped / 60, minute: clamped % 60)
        }

        isEnabled = defaults.object(forKey: Key.enabled) as? Bool ?? true
        isDarkroom = defaults.object(forKey: Key.darkroom) as? Bool ?? false
        pausedUntil = defaults.object(forKey: Key.pausedUntil) as? Date
        nightStart = timeOfDay(Key.nightStart, default: fallback.nightStart)
        nightEnd = timeOfDay(Key.nightEnd, default: fallback.nightEnd)
        transitionMinutes = defaults.object(forKey: Key.transition) as? Int ?? fallback.transitionMinutes
        dayKelvin = defaults.object(forKey: Key.dayKelvin) as? Double ?? fallback.dayKelvin
        nightKelvin = defaults.object(forKey: Key.nightKelvin) as? Double ?? fallback.nightKelvin
        darkroomBrightness = defaults.object(forKey: Key.darkroomBrightness) as? Double ?? 0.7
    }

    var state: DvskState {
        DvskState(isEnabled: isEnabled,
                  pausedUntil: pausedUntil,
                  isDarkroom: isDarkroom,
                  darkroomBrightness: darkroomBrightness,
                  schedule: Schedule(nightStart: nightStart,
                                     nightEnd: nightEnd,
                                     transitionMinutes: transitionMinutes,
                                     dayKelvin: dayKelvin,
                                     nightKelvin: nightKelvin))
    }
}
