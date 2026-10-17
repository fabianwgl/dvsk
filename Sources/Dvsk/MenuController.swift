import AppKit
import DvskCore

final class MenuController: NSObject, NSMenuDelegate {
    private let engine: Engine
    private let preferences: Preferences
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()

    private let statusLabelItem = NSMenuItem()
    private let enabledItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
    private let sliderItem = NSMenuItem()
    private let sliderTitle = NSTextField(labelWithString: "")
    private let slider = NSSlider(value: 2700, minValue: 1200, maxValue: 6500, target: nil, action: nil)
    private let darkroomItem = NSMenuItem(title: "Darkroom", action: #selector(toggleDarkroom), keyEquivalent: "")
    private let pauseItem = NSMenuItem(title: "Disable for an hour", action: #selector(togglePause), keyEquivalent: "")
    private let backlightItem = NSMenuItem()
    private let backlightTitle = NSTextField(labelWithString: "")
    private let backlightSlider = NSSlider(value: 0, minValue: 0, maxValue: 100, target: nil, action: nil)
    private let backlightAutoItem = NSMenuItem(title: "Adjust keyboard in low light", action: #selector(toggleBacklightAuto), keyEquivalent: "")
    private let backlightSeparator = NSMenuItem.separator()
    private let backlight = KeyboardBacklight()

    // Where macOS draws standard menu item titles and the end of the key-equivalent column.
    private static let leadingInset: CGFloat = 27
    private static let trailingInset: CGFloat = 13
    private var settingsWindow: SettingsWindowController?

    init(engine: Engine, preferences: Preferences) {
        self.engine = engine
        self.preferences = preferences
        super.init()
        buildMenu()
        statusItem.menu = menu
        engine.onUpdate = { [weak self] resolved in self?.refresh(resolved) }
        refresh(engine.lastResolved)
    }

    private func buildMenu() {
        menu.delegate = self
        menu.autoenablesItems = false

        statusLabelItem.isEnabled = false
        menu.addItem(statusLabelItem)
        menu.addItem(.separator())

        enabledItem.target = self
        menu.addItem(enabledItem)

        slider.target = self
        slider.action = #selector(sliderChanged)
        sliderItem.view = makeSliderView(label: sliderTitle, slider: slider)
        syncSlider()
        menu.addItem(sliderItem)

        darkroomItem.target = self
        menu.addItem(darkroomItem)

        pauseItem.target = self
        menu.addItem(pauseItem)
        menu.addItem(.separator())

        backlightSlider.target = self
        backlightSlider.action = #selector(backlightChanged)
        backlightItem.view = makeSliderView(label: backlightTitle, slider: backlightSlider)
        menu.addItem(backlightItem)

        backlightAutoItem.target = self
        menu.addItem(backlightAutoItem)
        menu.addItem(backlightSeparator)
        syncBacklight()

        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        let quit = NSMenuItem(title: "Quit Dvsk", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    private func makeSliderView(label: NSTextField, slider: NSSlider) -> NSView {
        let width: CGFloat = 250
        let inner = width - Self.leadingInset - Self.trailingInset
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: 48))
        container.autoresizingMask = [.width]

        label.font = .menuFont(ofSize: 13)
        label.frame = NSRect(x: Self.leadingInset, y: 28, width: inner, height: 16)
        label.autoresizingMask = [.width]
        container.addSubview(label)

        slider.isContinuous = true
        slider.frame = NSRect(x: Self.leadingInset, y: 6, width: inner, height: 20)
        slider.autoresizingMask = [.width]
        container.addSubview(slider)

        return container
    }

    private func syncSlider() {
        slider.doubleValue = preferences.nightKelvin
        sliderTitle.stringValue = "Night temperature: \(Int(preferences.nightKelvin))K"
    }

    /// Re-read on every open: the keyboard brightness keys change it behind our back.
    private func syncBacklight() {
        let available = backlight.isAvailable
        backlightItem.isHidden = !available
        backlightAutoItem.isHidden = !available
        backlightSeparator.isHidden = !available
        guard available else { return }
        let percent = Int((backlight.brightness * 100).rounded())
        backlightSlider.doubleValue = Double(percent)
        backlightTitle.stringValue = "Keyboard backlight: \(percent)%"
        backlightAutoItem.state = backlight.isAutoBrightnessEnabled ? .on : .off
    }

    // MARK: - Refresh

    private func refresh(_ resolved: ResolvedState) {
        // Follows the clock schedule only, so disabling or pausing never changes the icon.
        let night = preferences.state.schedule.nightWeight(at: Date()) >= 0.5
        let symbol = resolved.mode == .darkroom || night ? "moon" : "sun.max"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Dvsk")
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.imagePosition = .imageLeading
        // While paused, a countdown sits beside the unchanged icon.
        let countdown = pausedMinutesLeft.map { " \($0)m" } ?? ""
        statusItem.button?.attributedTitle = NSAttributedString(
            string: countdown,
            attributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)])

        switch resolved.mode {
        case .disabled:
            statusLabelItem.title = "Disabled"
        case .paused:
            let until = preferences.pausedUntil.map { Self.timeFormatter.string(from: $0) } ?? ""
            statusLabelItem.title = "Paused: \(pausedMinutesLeft ?? 0) min left (until \(until))"
        case .darkroom:
            statusLabelItem.title = "Darkroom"
        case .scheduled:
            statusLabelItem.title = "\(Int((resolved.kelvin ?? 0).rounded()))K, \(night ? "night" : "day")"
        }

        enabledItem.state = preferences.isEnabled ? .on : .off
        darkroomItem.state = preferences.isDarkroom ? .on : .off
        pauseItem.title = isPaused ? "Resume" : "Disable for an hour"
        pauseItem.isEnabled = preferences.isEnabled
    }

    /// Whole minutes left in the pause, rounded up so it never shows 0m while still paused.
    private var pausedMinutesLeft: Int? {
        guard let until = preferences.pausedUntil, preferences.isEnabled else { return nil }
        let remaining = until.timeIntervalSinceNow
        return remaining > 0 ? Int((remaining / 60).rounded(.up)) : nil
    }

    private var isPaused: Bool {
        preferences.pausedUntil.map { $0 > Date() } ?? false
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    func menuNeedsUpdate(_ menu: NSMenu) {
        syncSlider()
        syncBacklight()
        refresh(engine.lastResolved)
    }

    // MARK: - Actions

    @objc private func toggleEnabled() {
        preferences.isEnabled.toggle()
    }

    @objc private func toggleDarkroom() {
        preferences.pausedUntil = nil
        preferences.isDarkroom.toggle()
    }

    @objc private func togglePause() {
        preferences.pausedUntil = isPaused ? nil : Date().addingTimeInterval(3600)
    }

    @objc private func sliderChanged() {
        let kelvin = (slider.doubleValue / 10).rounded() * 10
        sliderTitle.stringValue = "Night temperature: \(Int(kelvin))K"
        preferences.pausedUntil = nil // touching the slider means "show me", so end any pause
        preferences.nightKelvin = kelvin
        engine.preview(kelvin: kelvin)
    }

    @objc private func backlightChanged() {
        let percent = Int(backlightSlider.doubleValue.rounded())
        backlightTitle.stringValue = "Keyboard backlight: \(percent)%"
        backlight.brightness = Float(percent) / 100
    }

    @objc private func toggleBacklightAuto() {
        backlight.isAutoBrightnessEnabled.toggle()
        backlightAutoItem.state = backlight.isAutoBrightnessEnabled ? .on : .off
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController(preferences: preferences)
        }
        settingsWindow?.show()
    }

    @objc private func quit() {
        engine.shutdown()
        NSApp.terminate(nil)
    }
}
