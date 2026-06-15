import Foundation

// MARK: - Geocoding (open-meteo geocoding API)

/// One result from `geocoding-api.open-meteo.com/v1/search`.
struct GeoResult: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let admin1: String?

    /// A friendly one-line label, e.g. "Kyoto, Kyoto, Japan".
    var displayName: String {
        var parts = [name]
        if let admin1, !admin1.isEmpty, admin1 != name { parts.append(admin1) }
        if let country, !country.isEmpty { parts.append(country) }
        return parts.joined(separator: ", ")
    }
}

struct GeoResponse: Codable {
    let results: [GeoResult]?
}

// MARK: - Forecast (open-meteo forecast API)

struct CurrentWeather: Codable {
    let temperature_2m: Double
    let weather_code: Int
    let wind_speed_10m: Double
    let relative_humidity_2m: Double
}

struct DailyWeather: Codable {
    let time: [String]
    let weather_code: [Int]
    let temperature_2m_max: [Double]
    let temperature_2m_min: [Double]
}

struct Forecast: Codable {
    let current: CurrentWeather
    let daily: DailyWeather
}

/// One day's worth of forecast, flattened for easy display.
struct DailyForecast: Identifiable {
    let id = UUID()
    let date: Date?
    let weekdayShort: String
    let code: Int
    let high: Double
    let low: Double
}

// MARK: - WMO weather-code mapping

/// Maps WMO weather interpretation codes to an SF Symbol and a short label.
/// Reference: https://open-meteo.com/en/docs (WMO Weather interpretation codes).
enum WeatherCode {
    /// Returns (SF Symbol name, human description) for a WMO code.
    static func info(for code: Int) -> (symbol: String, text: String) {
        switch code {
        case 0:
            return ("sun.max.fill", "Clear sky")
        case 1:
            return ("cloud.sun.fill", "Mainly clear")
        case 2:
            return ("cloud.sun.fill", "Partly cloudy")
        case 3:
            return ("cloud.fill", "Overcast")
        case 45, 48:
            return ("cloud.fog.fill", "Fog")
        case 51, 53, 55:
            return ("cloud.drizzle.fill", "Drizzle")
        case 56, 57:
            return ("cloud.sleet.fill", "Freezing drizzle")
        case 61, 63, 65:
            return ("cloud.rain.fill", "Rain")
        case 66, 67:
            return ("cloud.sleet.fill", "Freezing rain")
        case 71, 73, 75:
            return ("cloud.snow.fill", "Snow")
        case 77:
            return ("snowflake", "Snow grains")
        case 80, 81, 82:
            return ("cloud.heavyrain.fill", "Rain showers")
        case 85, 86:
            return ("cloud.snow.fill", "Snow showers")
        case 95:
            return ("cloud.bolt.fill", "Thunderstorm")
        case 96, 99:
            return ("cloud.bolt.rain.fill", "Thunderstorm with hail")
        default:
            return ("cloud.fill", "Unknown")
        }
    }

    static func symbol(for code: Int) -> String { info(for: code).symbol }
    static func text(for code: Int) -> String { info(for: code).text }
}
