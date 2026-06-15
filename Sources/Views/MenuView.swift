import SwiftUI

struct MenuView: View {
    @EnvironmentObject var model: AppModel
    @State private var showPaywall = false
    @State private var showSettings = false
    @State private var showSearch = false

    private var theme: AppTheme { model.settings.theme }
    private var weather: WeatherService { model.weather }

    var body: some View {
        VStack(spacing: 0) {
            if showSettings {
                SettingsView(onBack: { showSettings = false },
                             showPaywall: { showSettings = false; showPaywall = true })
                    .environmentObject(model)
            } else {
                main
            }
        }
        .frame(width: 320)
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(model)
        }
        .sheet(isPresented: $showSearch) {
            SearchView(requestPaywall: { showPaywall = true })
                .environmentObject(model)
        }
    }

    private var main: some View {
        VStack(spacing: 14) {
            header
            currentCard
            forecastStrip
            locationRow
            controlsRow

            Divider()

            if !model.isPro {
                unlockButton
            }

            footer
        }
        .padding(16)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Skylet").font(.headline)
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape").foregroundStyle(.secondary)
            }.buttonStyle(.plain)
        }
    }

    // MARK: - Current conditions card

    private var currentCard: some View {
        Group {
            if let f = weather.forecast, let loc = weather.selectedLocation {
                let info = WeatherCode.info(for: f.current.weather_code)
                let daily = weather.dailyForecasts.first
                VStack(spacing: 10) {
                    Text(loc.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(alignment: .center, spacing: 14) {
                        Image(systemName: info.symbol)
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                            .symbolRenderingMode(.hierarchical)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Int(f.current.temperature_2m.rounded()))\(weather.unitSuffix)")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(.white)
                            Text(info.text)
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }

                    HStack(spacing: 16) {
                        if let d = daily {
                            metric("thermometer.high", "\(Int(d.high.rounded()))°")
                            metric("thermometer.low", "\(Int(d.low.rounded()))°")
                        }
                        metric("humidity.fill", "\(Int(f.current.relative_humidity_2m.rounded()))%")
                        metric("wind", "\(Int(f.current.wind_speed_10m.rounded()))")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LinearGradient(colors: theme.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                )
            } else {
                emptyOrError
            }
        }
    }

    private var emptyOrError: some View {
        VStack(spacing: 8) {
            if weather.loading {
                ProgressView()
                Text("Loading weather…").font(.caption).foregroundStyle(.secondary)
            } else if let err = weather.errorMessage {
                Image(systemName: "wifi.exclamationmark").font(.system(size: 26)).foregroundStyle(.secondary)
                Text(err).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Button("Retry") { Task { await weather.refresh() } }.buttonStyle(.link).font(.caption)
            } else {
                Image(systemName: "location.magnifyingglass").font(.system(size: 26)).foregroundStyle(.secondary)
                Text("Add a location to see the weather.").font(.caption).foregroundStyle(.secondary)
                Button {
                    showSearch = true
                } label: {
                    Text("＋ Add location").font(.system(size: 12, weight: .medium))
                }.buttonStyle(.link)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
    }

    private func metric(_ symbol: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).font(.system(size: 11)).foregroundStyle(.white.opacity(0.9))
            Text(value).font(.system(size: 12, weight: .medium)).foregroundStyle(.white)
        }
    }

    // MARK: - Forecast strip

    private var forecastStrip: some View {
        Group {
            let days = weather.dailyForecasts
            if days.count > 1 {
                let visibleCount = model.isPro ? days.count : min(3, days.count)
                let visible = Array(days.prefix(visibleCount))
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text(model.isPro ? "7-day forecast" : "Forecast").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        if !model.isPro {
                            Button { showPaywall = true } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "crown.fill").font(.system(size: 8))
                                    Text("Unlock 7-day").font(.system(size: 10, weight: .medium))
                                }.foregroundStyle(theme.accent)
                            }.buttonStyle(.plain)
                        }
                    }
                    HStack(spacing: 6) {
                        ForEach(visible) { day in
                            VStack(spacing: 4) {
                                Text(day.weekdayShort).font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
                                Image(systemName: WeatherCode.symbol(for: day.code))
                                    .font(.system(size: 15))
                                    .foregroundStyle(theme.accent)
                                    .symbolRenderingMode(.hierarchical)
                                Text("\(Int(day.high.rounded()))°").font(.system(size: 11, weight: .semibold))
                                Text("\(Int(day.low.rounded()))°").font(.system(size: 10)).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(Color.primary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Location picker row

    private var locationRow: some View {
        HStack(spacing: 8) {
            if weather.locations.isEmpty {
                Button { showSearch = true } label: {
                    Label("Add location", systemImage: "plus")
                        .font(.system(size: 12, weight: .medium))
                }.buttonStyle(.plain)
            } else {
                Menu {
                    ForEach(Array(weather.locations.enumerated()), id: \.element.id) { idx, loc in
                        Button {
                            weather.select(idx)
                        } label: {
                            if idx == weather.selectedIndex {
                                Label(loc.name, systemImage: "checkmark")
                            } else {
                                Text(loc.name)
                            }
                        }
                    }
                    Divider()
                    Button("Add location…") { showSearch = true }
                    if weather.locations.indices.contains(weather.selectedIndex) {
                        Button("Remove current", role: .destructive) {
                            weather.remove(at: weather.selectedIndex)
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "mappin.and.ellipse").font(.system(size: 11))
                        Text(weather.selectedLocation?.name ?? "Location").font(.system(size: 12)).lineLimit(1)
                    }
                }
                .menuStyle(.borderlessButton)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer()
        }
    }

    // MARK: - Controls row (unit toggle + refresh)

    private var controlsRow: some View {
        HStack(spacing: 8) {
            // Unit toggle (free)
            HStack(spacing: 0) {
                unitButton("°C", celsius: true)
                unitButton("°F", celsius: false)
            }
            .background(Color.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Spacer()

            Button {
                Task { await weather.refresh() }
            } label: {
                HStack(spacing: 4) {
                    if weather.loading {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise").font(.system(size: 11))
                    }
                    Text("Refresh").font(.system(size: 12))
                }
                .padding(.vertical, 6).padding(.horizontal, 10)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(weather.selectedLocation == nil)
        }
    }

    private func unitButton(_ label: String, celsius: Bool) -> some View {
        let selected = weather.unitCelsius == celsius
        return Button {
            if weather.unitCelsius != celsius { weather.unitCelsius = celsius }
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(selected ? AnyShapeStyle(.white) : AnyShapeStyle(Color.secondary))
                .padding(.vertical, 6).padding(.horizontal, 12)
                .background(selected ? AnyShapeStyle(theme.accent) : AnyShapeStyle(Color.clear))
        }.buttonStyle(.plain)
    }

    // MARK: - Unlock + footer

    private var unlockButton: some View {
        Button(action: { showPaywall = true }) {
            HStack {
                Image(systemName: "crown.fill")
                Text("Unlock Skylet Pro").bold()
                Spacer()
                if !model.entitlements.priceText.isEmpty {
                    Text(model.entitlements.priceText).font(.caption).opacity(0.9)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9).padding(.horizontal, 12)
            .background(LinearGradient(colors: theme.gradient, startPoint: .leading, endPoint: .trailing))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }.buttonStyle(.plain)
    }

    private var footer: some View {
        HStack {
            Button("Settings") { showSettings = true }.buttonStyle(.link)
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }.buttonStyle(.link)
        }
        .font(.caption)
    }
}
