import Foundation

/// A place the user wants to track weather for. Persisted to UserDefaults as
/// JSON. Geocoded once (via Open-Meteo) and then stored by coordinate.
struct SavedLocation: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var latitude: Double
    var longitude: Double
}
