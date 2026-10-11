import AppKit
import DvskCore

final class MenuController: NSObject, NSMenuDelegate {
    private let engine: Engine
    private let preferences: Preferences
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()

    private let statusLabelItem = NSMenuItem()
    private let enabledItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
    private let sliderItem = NSMenuItem()
    private let sliderTitle = NSTextField(labelWithString: "")
    private let slider = NSSlider(value: 2700, minValue: 1200, maxValue: 6500, target: nil, action: nil)
    private let darkroomItem = NSMenuItem(title: "Darkroom", action: #selector(toggleDarkroom), keyEquivalent: "")
    private let pauseItem = NSMenuItem(title: "Disable for an hour", action: #selector(togglePause), keyEquivalent: "")
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

        sliderItem.view = makeSliderView()
        menu.addItem(sliderItem)

        darkroomItem.target = self
        menu.addItem(darkroomItem)

        pauseItem.target = self
        menu.addItem(pauseItem)
        menu.addItem(.separator())

        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        let quit = NSMenuItem(title: "Quit Dvsk", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    private func makeSliderView() -> NSView {
        let width: CGFloat = 250
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: 48))

        sliderTitle.font = .menuFont(ofSize: 13)
        sliderTitle.frame = NSRect(x: 14, y: 28, width: width - 28, height: 16)
        container.addSubview(sliderTitle)

        slider.isContinuous = true
        slider.target = self
        slider.action = #selector(sliderChanged)
        slider.frame = NSRect(x: 14, y: 6, width: width - 28, height: 20)
        container.addSubview(slider)

        syncSlider()
        return container
    }

    private func syncSlider() {
        slider.doubleValue = preferences.nightKelvin
        sliderTitle.stringValue = "Night temperature: \(Int(preferences.nightKelvin))K"
    }

    // MARK: - Refresh

    private func refresh(_ resolved: ResolvedState) {
        // Follows the clock schedule only, so disabling or pausing never changes the icon.
        let night = preferences.state.schedule.nightWeight(at: Date()) >= 0.5
        let symbol = resolved.mode == .darkroom || night ? "moon" : "sun.max"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Dvsk")
        image?.isTemplate = true
        statusItem.button?.image = image

        switch resolved.mode {
        case .disabled:
            statusLabelItem.title = "Disabled"
        case .paused:
            let until = preferences.pausedUntil.map { Self.timeFormatter.string(from: $0) } ?? ""
            statusLabelItem.title = "Paused until \(until)"
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
