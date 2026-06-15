import SwiftUI

@main
struct SkyletApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .environmentObject(model)
        } label: {
            // Show the live temperature next to a weather glyph when enabled and
            // a forecast is available; otherwise fall back to a plain icon.
            if model.settings.showTempInMenuBar, model.weather.forecast != nil {
                // A single Text combining the symbol and temperature renders
                // reliably in the menu bar (unlike a multi-view HStack label).
                Text("\(Image(systemName: model.currentSymbol)) \(model.weather.menuBarText)")
            } else {
                Image(systemName: "cloud.sun.fill")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
