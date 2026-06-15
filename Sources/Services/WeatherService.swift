import Foundation
import Combine

/// Fetches weather from the free Open-Meteo API (no key required), persists the
/// user's saved locations, and keeps the current forecast up to date.
@MainActor
final class WeatherService: ObservableObject {
    // Persisted state
    @Published var locations: [SavedLocation] = [] {
        didSet { persistLocations() }
    }
    @Published var selectedIndex: Int = 0 {
        didSet { d.set(selectedIndex, forKey: Self.selectedKey) }
    }
    @Published var unitCelsius: Bool {
        didSet {
            d.set(unitCelsius, forKey: Self.celsiusKey)
            Task { await refresh() }
        }
    }

    // Live state
    @Published private(set) var forecast: Forecast?
    @Published private(set) var loading = false
    @Published var errorMessage: String?

    private let d = UserDefaults.standard
    private static let locationsKey = "skylet.locations"
    private static let selectedKey = "skylet.selectedIndex"
    private static let celsiusKey = "skylet.celsius"

    private var timer: Timer?
    private let session = URLSession.shared

    init() {
        unitCelsius = d.object(forKey: Self.celsiusKey) as? Bool ?? true

        if let data = d.data(forKey: Self.locationsKey),
           let saved = try? JSONDecoder().decode([SavedLocation].self, from: data) {
            locations = saved
        }
        selectedIndex = d.object(forKey: Self.selectedKey) as? Int ?? 0
        clampSelection()

        Task { await refresh() }

        // Auto-refresh every 15 minutes.
        timer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refresh() }
        }
    }

    // MARK: - Derived state

    var selectedLocation: SavedLocation? {
        guard locations.indices.contains(selectedIndex) else { return nil }
        return locations[selectedIndex]
    }

    /// The text shown next to the menu-bar icon, e.g. "21°".
    var menuBarText: String {
        guard let t = forecast?.current.temperature_2m else { return "--°" }
        return "\(Int(t.rounded()))°"
    }

    var unitSuffix: String { unitCelsius ? "°C" : "°F" }

    /// Flattened daily forecast for display.
    var dailyForecasts: [DailyForecast] {
        guard let daily = forecast?.daily else { return [] }
        let count = min(daily.time.count,
                        min(daily.weather_code.count,
                            min(daily.temperature_2m_max.count, daily.temperature_2m_min.count)))
        var out: [DailyForecast] = []
        for i in 0..<count {
            let date = Self.dayParser.date(from: daily.time[i])
            let label = date.map { Self.weekdayFormatter.string(from: $0) } ?? daily.time[i]
            out.append(DailyForecast(date: date,
                                     weekdayShort: label,
                                     code: daily.weather_code[i],
                                     high: daily.temperature_2m_max[i],
                                     low: daily.temperature_2m_min[i]))
        }
        return out
    }

    // MARK: - Search

    /// Geocode a free-text query into candidate locations. Returns [] on error.
    func search(_ query: String) async -> [SavedLocation] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(encoded)&count=5&language=en&format=json")
        else { return [] }

        do {
            let (data, _) = try await session.data(from: url)
            let decoded = try JSONDecoder().decode(GeoResponse.self, from: data)
            let results = decoded.results ?? []
            return results.map {
                SavedLocation(name: $0.displayName, latitude: $0.latitude, longitude: $0.longitude)
            }
        } catch {
            return []
        }
    }

    // MARK: - Mutations

    func add(_ location: SavedLocation) {
        locations.append(location)
        selectedIndex = locations.count - 1
        Task { await refresh() }
    }

    func remove(at index: Int) {
        guard locations.indices.contains(index) else { return }
        locations.remove(at: index)
        clampSelection()
        Task { await refresh() }
    }

    func select(_ index: Int) {
        guard locations.indices.contains(index) else { return }
        selectedIndex = index
        Task { await refresh() }
    }

    // MARK: - Forecast

    func refresh() async {
        guard let loc = selectedLocation else {
            forecast = nil
            errorMessage = nil
            return
        }
        let unit = unitCelsius ? "celsius" : "fahrenheit"
        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        comps?.queryItems = [
            URLQueryItem(name: "latitude", value: String(loc.latitude)),
            URLQueryItem(name: "longitude", value: String(loc.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m"),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min"),
            URLQueryItem(name: "temperature_unit", value: unit),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "7"),
        ]
        guard let url = comps?.url else {
            errorMessage = "Couldn't build the request."
            return
        }

        loading = true
        defer { loading = false }
        do {
            let (data, _) = try await session.data(from: url)
            let decoded = try JSONDecoder().decode(Forecast.self, from: data)
            forecast = decoded
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't load weather. Check your connection and try again."
        }
    }

    // MARK: - Persistence helpers

    private func persistLocations() {
        if let data = try? JSONEncoder().encode(locations) {
            d.set(data, forKey: Self.locationsKey)
        }
    }

    private func clampSelection() {
        if locations.isEmpty {
            selectedIndex = 0
        } else if !locations.indices.contains(selectedIndex) {
            selectedIndex = max(0, min(selectedIndex, locations.count - 1))
        }
    }

    // MARK: - Formatters

    private static let dayParser: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE"
        return f
    }()
}
