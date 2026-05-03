import Foundation

enum AppConstants {
    static let appDisplayName = "QuickNew"
    static let finderExtensionBundleIdentifier = "com.panjing.RightMenu.FinderExtension"
    static let appGroupIdentifier = "group.com.panjing.RightMenu"
    static let settingsDirectoryName = "RightMenu"
    static let settingsFileName = "Preferences.plist"
}

enum L10n {
    static let languageChangedNotification = Notification.Name("QuickNewLanguageChanged")

    static func string(_ key: String) -> String {
        NSLocalizedString(key, bundle: localizedBundle, comment: "")
    }

    static func setLanguage(_ language: AppLanguage) {
        PreferencesStore.shared.set(language.rawValue, forKey: AppLanguage.preferencesKey)
        NotificationCenter.default.post(name: languageChangedNotification, object: nil)
    }

    static var currentLanguage: AppLanguage {
        PreferencesStore.shared.reload()
        guard let rawValue = PreferencesStore.shared.object(forKey: AppLanguage.preferencesKey) as? String,
              let language = AppLanguage(rawValue: rawValue) else {
            return .system
        }
        return language
    }

    private static var localizedBundle: Bundle {
        let bundle = hostBundle
        guard let identifier = currentLanguage.bundleIdentifier,
              let path = bundle.path(forResource: identifier, ofType: "lproj"),
              let localized = Bundle(path: path) else {
            return bundle
        }
        return localized
    }

    private static var hostBundle: Bundle {
        let mainURL = Bundle.main.bundleURL
        if mainURL.pathExtension == "app" {
            return .main
        }

        if mainURL.pathExtension == "appex" {
            let appURL = mainURL
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
            if let bundle = Bundle(url: appURL) {
                return bundle
            }
        }
        return .main
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case simplifiedChinese
    case traditionalChinese

    static let preferencesKey = "appLanguage"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: L10n.string("language.system")
        case .english: "English"
        case .simplifiedChinese: "简体中文"
        case .traditionalChinese: "繁體中文"
        }
    }

    var bundleIdentifier: String? {
        switch self {
        case .system: nil
        case .english: "en"
        case .simplifiedChinese: "zh-Hans"
        case .traditionalChinese: "zh-Hant"
        }
    }
}
