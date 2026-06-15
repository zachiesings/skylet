import SwiftUI

/// Lightweight, observable user preferences backed by `UserDefaults`.
final class Settings: ObservableObject {
    static let shared = Settings()
    private let d = UserDefaults.standard

    @Published var themeID: String {
        didSet { d.set(themeID, forKey: "skylet.theme") }
    }
    @Published var launchAtLogin: Bool {
        didSet {
            d.set(launchAtLogin, forKey: "skylet.launchAtLogin")
            LoginItem.setEnabled(launchAtLogin)
        }
    }
    @Published var showTempInMenuBar: Bool {
        didSet { d.set(showTempInMenuBar, forKey: "skylet.showTemp") }
    }

    var theme: AppTheme { AppTheme(rawValue: themeID) ?? .aurora }

    private init() {
        themeID = d.string(forKey: "skylet.theme") ?? AppTheme.aurora.rawValue
        showTempInMenuBar = d.object(forKey: "skylet.showTemp") as? Bool ?? true
        launchAtLogin = LoginItem.isEnabled
    }
}
