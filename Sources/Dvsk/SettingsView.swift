import AppKit
import SwiftUI
import DvskCore

private enum TemperaturePhaseTab: String, CaseIterable, Identifiable {
    case daytime = "Daytime"
    case sunset = "Sunset"
    case bedtime = "Bedtime"

    var id: String { rawValue }
}

private final class SettingsUIState: ObservableObject {
    @Published var selectedPhase: TemperaturePhaseTab = .sunset
    @Published var coordinatesText: String
    @Published var coordinatesError: String?
    @Published var now = Date()

    private var clockTimer: Timer?

    init(latitude: Double, longitude: Double) {
        self.coordinatesText = String(format: "%.4g, %.4g", latitude, longitude)
    }

    func startClock() {
        now = Date()
        clockTimer?.invalidate()
        let timer = Timer(timeInterval: 60, repeats: true) { [weak self] _ in
            self?.now = Date()
        }
        RunLoop.main.add(timer, forMode: .common)
        clockTimer = timer
    }

    deinit {
        clockTimer?.invalidate()
    }
}

struct SettingsView: View {
    @ObservedObject var preferences: Preferences
    @ObservedObject private var uiState: SettingsUIState

    fileprivate init(preferences: Preferences, uiState: SettingsUIState) {
        self.preferences = preferences
        self.uiState = uiState
    }

    var body: some View {
        let isFixed = preferences.scheduleMode == .fixed
        VStack(alignment: .leading, spacing: 14) {
            Picker("Schedule", selection: $preferences.scheduleMode) {
                Text("Fixed times").tag(ScheduleMode.fixed)
                Text("Sun & Wake").tag(ScheduleMode.circadian)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            // Keep both tabs mounted so AppKit controls (TextField, DatePicker) are never
            // torn down and recreated on toggle, making mode switching instantaneous.
            // The hidden one is disabled so it leaves the key-view loop: Tab and the window's
            // initial first responder can't land on a control the user can't see.
            ZStack(alignment: .topLeading) {
                fixedSection
                    .opacity(isFixed ? 1 : 0)
                    .allowsHitTesting(isFixed)
                    .accessibilityHidden(!isFixed)
                    .disabled(!isFixed)

                circadianSection
                    .opacity(isFixed ? 0 : 1)
                    .allowsHitTesting(!isFixed)
                    .accessibilityHidden(isFixed)
                    .disabled(isFixed)
            }
        }
        .padding(18)
        .frame(width: 440, height: 500, alignment: .top)
    }

    @ViewBuilder
    private var fixedSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Night starts")
                    Spacer()
                    DatePicker("", selection: binding(for: \.nightStart), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.stepperField)
                }
                Divider()
                HStack {
                    Text("Night ends")
                    Spacer()
                    DatePicker("", selection: binding(for: \.nightEnd), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.stepperField)
                }
                Divider()
                HStack {
                    Text("Fade: \(preferences.transitionMinutes) min")
                    Spacer()
                    Stepper("", value: $preferences.transitionMinutes, in: 0...180, step: 5)
                        .labelsHidden()
                }
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Night temperature: \(Int(preferences.nightKelvin))K")
                    Slider(value: $preferences.nightKelvin, in: 1200...6500, step: 10)
                }
            }
            .padding(6)
        }
    }

    @ViewBuilder
    private var circadianSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    CircadianCurveView(schedule: preferences.state.schedule, now: uiState.now)
                        .frame(height: 112)

                    Picker("Phase", selection: $uiState.selectedPhase) {
                        Text("Day · \(Int(preferences.dayKelvin))K").tag(TemperaturePhaseTab.daytime)
                        Text("Sunset · \(Int(preferences.nightKelvin))K").tag(TemperaturePhaseTab.sunset)
                        Text("Bedtime · \(Int(preferences.bedtimeKelvin))K").tag(TemperaturePhaseTab.bedtime)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(uiState.selectedPhase.rawValue): \(Int(activePhaseKelvin.wrappedValue))K")
                            Spacer()
                            Button("Recommended") {
                                preferences.dayKelvin = 6500
                                preferences.nightKelvin = 3400
                                preferences.bedtimeKelvin = 1900
                            }
                            .controlSize(.small)
                        }
                        Slider(value: activePhaseKelvin, in: 1200...6500, step: 10)
                    }
                }
                .padding(6)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 9) {
                    HStack {
                        Text("Wake time")
                        Spacer()
                        DatePicker("", selection: binding(for: \.wakeTime), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(.stepperField)
                    }
                    Divider()
                    HStack {
                        Text("Bedtime: \(formatHours(preferences.bedtimeHoursBeforeWake)) before wake (\(formatMinutes(preferences.state.schedule.bedtimeStartMinutes)))")
                        Spacer()
                        Stepper("", value: $preferences.bedtimeHoursBeforeWake, in: 6...12, step: 0.5)
                            .labelsHidden()
                    }
                    Divider()
                    HStack {
                        Text("Fade: \(preferences.transitionMinutes) min")
                        Spacer()
                        Stepper("", value: $preferences.transitionMinutes, in: 0...180, step: 5)
                            .labelsHidden()
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Location (lat, lon)")
                            Spacer()
                            TextField("51.51, -0.13", text: $uiState.coordinatesText)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .frame(width: 150)
                                .multilineTextAlignment(.trailing)
                                .onSubmit { applyCoordinates() }
                                .onChange(of: uiState.coordinatesText) { _, _ in applyCoordinates() }
                        }
                        if let coordinatesError = uiState.coordinatesError {
                            Text(coordinatesError)
                                .font(.caption)
                                .foregroundStyle(.red)
                        } else {
                            Text(String(format: "Latitude %.4f, Longitude %.4f (local calculation, no network)",
                                        preferences.latitude, preferences.longitude))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(6)
            }
        }
    }

    private var activePhaseKelvin: Binding<Double> {
        switch uiState.selectedPhase {
        case .daytime: return $preferences.dayKelvin
        case .sunset: return $preferences.nightKelvin
        case .bedtime: return $preferences.bedtimeKelvin
        }
    }

    private func applyCoordinates() {
        let parts = uiState.coordinatesText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2,
              let lat = Double(parts[0]),
              let lon = Double(parts[1]),
              (-90.0...90.0).contains(lat),
              (-180.0...180.0).contains(lon) else {
            uiState.coordinatesError = "Enter latitude (-90…90) and longitude (-180…180), e.g. 51.51, -0.13"
            return
        }
        uiState.coordinatesError = nil
        preferences.latitude = lat
        preferences.longitude = lon
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

    private func formatHours(_ hours: Double) -> String {
        if hours.rounded() == hours {
            return "\(Int(hours))h"
        }
        return String(format: "%.1fh", hours)
    }

    private func formatMinutes(_ minutes: Double) -> String {
        let rounded = Int(minutes.rounded()) % 1440
        let h = (rounded < 0 ? rounded + 1440 : rounded) / 60
        let m = (rounded < 0 ? rounded + 1440 : rounded) % 60
        return String(format: "%02d:%02d", h, m)
    }
}

/// 24-hour circadian temperature preview anchored at wake time, with colour-coded phase bar
/// and live current-time indicator.
private struct CircadianCurveView: View {
    let schedule: Schedule
    let now: Date

    var body: some View {
        let solar = schedule.solarTimes(for: now)
        let samples = schedule.dailyCurve(on: now, steps: 96)
        let nowKelvin = schedule.targetKelvin(at: now)
        let nowOffset = offsetFromWake(now)

        VStack(alignment: .leading, spacing: 6) {
            Text(summaryLine(solar: solar, nowKelvin: nowKelvin))
                .font(.caption)
                .foregroundStyle(.secondary)

            Canvas { ctx, size in
                let plotBottom = max(1, size.height - 22)
                let minK = 1000.0
                let maxK = 6800.0

                func xPos(_ offset: Double) -> CGFloat {
                    CGFloat(offset / 1440.0) * size.width
                }

                func yPos(_ kelvin: Double) -> CGFloat {
                    let norm = min(max((kelvin - minK) / (maxK - minK), 0), 1)
                    return plotBottom - CGFloat(norm) * (plotBottom - 10) - 4
                }

                func offsetOf(_ minuteOfDay: Double) -> Double {
                    let wakeMin = Double(schedule.wakeTime.minutesSinceMidnight)
                    let diff = (minuteOfDay - wakeMin).truncatingRemainder(dividingBy: 1440)
                    return diff < 0 ? diff + 1440 : diff
                }

                // Subtle vertical guides at key transitions
                var guideOffsets: [Double] = [offsetOf(schedule.bedtimeStartMinutes)]
                if let sunrise = solar.sunriseMinutes { guideOffsets.append(offsetOf(sunrise)) }
                if let sunset = solar.sunsetMinutes { guideOffsets.append(offsetOf(sunset)) }
                for offset in guideOffsets {
                    let gx = xPos(offset)
                    var line = Path()
                    line.move(to: CGPoint(x: gx, y: 4))
                    line.addLine(to: CGPoint(x: gx, y: plotBottom))
                    ctx.stroke(line, with: .color(.primary.opacity(0.1)), lineWidth: 1)
                }

                var curvePath = Path()
                for (index, sample) in samples.enumerated() {
                    let pt = CGPoint(x: xPos(sample.offsetMinutes), y: yPos(sample.kelvin))
                    if index == 0 {
                        curvePath.move(to: pt)
                    } else {
                        curvePath.addLine(to: pt)
                    }
                }

                var fillPath = curvePath
                fillPath.addLine(to: CGPoint(x: size.width, y: plotBottom))
                fillPath.addLine(to: CGPoint(x: 0, y: plotBottom))
                fillPath.closeSubpath()

                let fillGradient = Gradient(colors: [
                    Color.orange.opacity(0.32),
                    Color.orange.opacity(0.06)
                ])
                ctx.fill(fillPath,
                         with: .linearGradient(fillGradient,
                                               startPoint: CGPoint(x: 0, y: plotBottom),
                                               endPoint: CGPoint(x: 0, y: 0)))

                ctx.stroke(curvePath, with: .color(.primary.opacity(0.35)), lineWidth: 1.5)

                // Bottom phase bar merged into contiguous runs (typically 3-4 rects)
                let barY = plotBottom + 2
                let count = samples.count - 1
                var runStart = 0
                while runStart < count {
                    let phase = samples[runStart].phase
                    var runEnd = runStart + 1
                    while runEnd < count && samples[runEnd].phase == phase {
                        runEnd += 1
                    }
                    let x0 = xPos(samples[runStart].offsetMinutes)
                    let x1 = xPos(samples[runEnd].offsetMinutes)
                    let rect = CGRect(x: x0, y: barY, width: max(1, x1 - x0), height: 3)
                    ctx.fill(Path(rect), with: .color(phaseColor(phase)))
                    runStart = runEnd
                }

                // Event time labels positioned at their true x-coordinates, skipping collisions
                struct AxisLabel {
                    let x: CGFloat
                    let text: String
                    let anchor: UnitPoint
                }
                let wakeClock = formatClock(Double(schedule.wakeTime.minutesSinceMidnight))
                let bedOffset = offsetOf(schedule.bedtimeStartMinutes)
                let bedClock = formatClock(schedule.bedtimeStartMinutes)

                var candidates: [AxisLabel] = [
                    AxisLabel(x: 2, text: "Wake \(wakeClock)", anchor: .leading)
                ]
                if let sunset = solar.sunsetMinutes {
                    let sx = min(max(xPos(offsetOf(sunset)), 36), size.width - 36)
                    candidates.append(AxisLabel(x: sx, text: "Sunset \(formatClock(sunset))", anchor: .center))
                }
                let bx = min(max(xPos(bedOffset), 36), size.width - 36)
                candidates.append(AxisLabel(x: bx, text: "Bed \(bedClock)", anchor: .center))
                if let sunrise = solar.sunriseMinutes {
                    let rx = min(max(xPos(offsetOf(sunrise)), 36), size.width - 36)
                    candidates.append(AxisLabel(x: rx, text: "Rise \(formatClock(sunrise))", anchor: .center))
                }

                var placedCenters: [CGFloat] = []
                let labelY = plotBottom + 13
                for item in candidates {
                    let approxCenter = item.anchor == .leading ? item.x + 28 : item.x
                    let collides = placedCenters.contains { abs($0 - approxCenter) < 62 }
                    if collides { continue }
                    placedCenters.append(approxCenter)
                    let resolved = ctx.resolve(
                        Text(item.text)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    )
                    ctx.draw(resolved, at: CGPoint(x: item.x, y: labelY), anchor: item.anchor)
                }

                let dotCenter = CGPoint(x: xPos(nowOffset), y: yPos(nowKelvin))
                let dotRect = CGRect(x: dotCenter.x - 5, y: dotCenter.y - 5, width: 10, height: 10)
                ctx.fill(Path(ellipseIn: dotRect), with: .color(.accentColor.opacity(0.85)))
                ctx.stroke(Path(ellipseIn: dotRect), with: .color(.white.opacity(0.9)), lineWidth: 1.5)
            }
            .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary.opacity(0.45)))
        }
    }

    private func phaseColor(_ phase: SchedulePhase) -> Color {
        switch phase {
        case .daytime: return .blue.opacity(0.55)
        case .sunset: return .orange.opacity(0.75)
        case .bedtime: return .red.opacity(0.75)
        }
    }

    private func offsetFromWake(_ date: Date) -> Double {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        let nowMin = Double((parts.hour ?? 0) * 60 + (parts.minute ?? 0))
        let wakeMin = Double(schedule.wakeTime.minutesSinceMidnight)
        let diff = (nowMin - wakeMin).truncatingRemainder(dividingBy: 1440)
        return diff < 0 ? diff + 1440 : diff
    }

    private func summaryLine(solar: SolarTimes, nowKelvin: Double) -> String {
        let k = "\(Int(nowKelvin.rounded()))K"
        let bed = formatClock(schedule.bedtimeStartMinutes)
        if solar.isPolarDay {
            return "Polar day · Bedtime \(bed) · Now \(k)"
        }
        if solar.isPolarNight {
            return "Polar night · Bedtime \(bed) · Now \(k)"
        }
        if let sunrise = solar.sunriseMinutes, let sunset = solar.sunsetMinutes {
            let hours = Int(solar.daylightMinutes) / 60
            let mins = Int(solar.daylightMinutes) % 60
            return "Sunrise \(formatClock(sunrise)) · Sunset \(formatClock(sunset)) (\(hours)h \(mins)m) · Now \(k)"
        }
        return "Bedtime \(bed) · Now \(k)"
    }

    private func formatClock(_ minutes: Double) -> String {
        let rounded = Int(minutes.rounded()) % 1440
        let pos = rounded < 0 ? rounded + 1440 : rounded
        return String(format: "%02d:%02d", pos / 60, pos % 60)
    }
}

final class SettingsWindowController {
    private let window: NSWindow
    private let uiState: SettingsUIState

    init(preferences: Preferences) {
        let uiState = SettingsUIState(latitude: preferences.latitude, longitude: preferences.longitude)
        self.uiState = uiState
        let controller = NSHostingController(rootView: SettingsView(preferences: preferences, uiState: uiState))
        window = NSWindow(contentViewController: controller)
        window.title = "Dvsk Settings"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
    }

    func show() {
        uiState.startClock()
        window.center()
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }
}
