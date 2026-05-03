import SwiftUI

@main
struct RightMenuApp: App {
    @StateObject private var authorization = AuthorizationStatusStore()
    @StateObject private var language = LanguageSettingsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authorization)
                .environmentObject(language)
                .id(language.revision)
                .frame(minWidth: 680, minHeight: 500)
                .onReceive(NotificationCenter.default.publisher(for: L10n.languageChangedNotification)) { _ in
                    language.refreshText()
                }
        }
        .windowStyle(.hiddenTitleBar)

        Settings {
            SettingsView()
                .environmentObject(language)
                .id(language.revision)
                .frame(width: 520)
                .onReceive(NotificationCenter.default.publisher(for: L10n.languageChangedNotification)) { _ in
                    language.refreshText()
                }
        }
    }
}
