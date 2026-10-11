import AppKit
import SwiftUI
import DvskCore

struct SettingsView: View {
    @ObservedObject var preferences: Preferences

    var body: some View {
        Form {
            DatePicker("Night starts", selection: binding(for: \.nightStart), displayedComponents: .hourAndMinute)
            DatePicker("Night ends", selection: binding(for: \.nightEnd), displayedComponents: .hourAndMinute)

            Stepper(value: $preferences.transitionMinutes, in: 0...180, step: 5) {
                Text("Fade: \(preferences.transitionMinutes) min")
            }

            VStack(alignment: .leading) {
                Text("Night temperature: \(Int(preferences.nightKelvin))K")
                Slider(value: $preferences.nightKelvin, in: 1200...6500, step: 10)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func binding(for keyPath: ReferenceWritableKeyPath<Preferences, TimeOfDay>) -> Binding<Date> {
        Binding(
            get: {
                let time = preferences[keyPath: keyPath]
                return Calendar.current.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: Date()) ?? Date()
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                preferences[keyPath: keyPath] = TimeOfDay(hour: parts.hour ?? 0, minute: parts.minute ?? 0)
            }
        )
    }
}

final class SettingsWindowController {
    private let window: NSWindow

    init(preferences: Preferences) {
        let controller = NSHostingController(rootView: SettingsView(preferences: preferences))
        window = NSWindow(contentViewController: controller)
        window.title = "Dvsk Settings"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
    }

    func show() {
        window.center()
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }
}
