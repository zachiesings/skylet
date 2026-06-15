import SwiftUI
import Combine

@MainActor
final class AppModel: ObservableObject {
    let weather = WeatherService()
    let entitlements = Entitlements()
    let settings = Settings.shared

    private var bag = Set<AnyCancellable>()

    init() {
        // Re-broadcast nested ObservableObject changes so SwiftUI views update.
        weather.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &bag)
        entitlements.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &bag)
        settings.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &bag)
    }

    var isPro: Bool { entitlements.isPro }

    /// Free tier is limited to a single saved location; Pro is unlimited.
    var canAddLocation: Bool { isPro || weather.locations.count < 1 }

    /// SF Symbol for the currently selected location's conditions.
    var currentSymbol: String {
        guard let code = weather.forecast?.current.weather_code else { return "cloud.sun.fill" }
        return WeatherCode.symbol(for: code)
    }
}
