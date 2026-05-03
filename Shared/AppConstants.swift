import Foundation

enum AppConstants {
    static let appDisplayName = "QuickNew"
    static let finderExtensionBundleIdentifier = "com.panjing.RightMenu.FinderExtension"
    static let appGroupIdentifier = "group.com.panjing.RightMenu"
    static let appBundleIdentifier = "com.panjing.RightMenu"
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

    /// Find the correct bundle for localization.
    /// In FinderSync extensions, Bundle.main is Finder's bundle, NOT our extension's.
    /// We must find our container app bundle via bundle identifier.
    private static var hostBundle: Bundle {
        // In FinderSync extension: Bundle.main = Finder, Bundle.main.bundleIdentifier != ours
        // Use Bundle(identifier:) to find the correct bundle.
        // This works because both the app and extension bundles are loaded in the process.

        // Try the main app bundle first (contains all localization strings)
        if let appBundle = Bundle(identifier: AppConstants.appBundleIdentifier) {
            return appBundle
        }

        // Try the extension bundle, then navigate to the container app
        if let extBundle = Bundle(identifier: AppConstants.finderExtensionBundleIdentifier) {
            let appURL = extBundle.bundleURL
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
            if let bundle = Bundle(url: appURL) {
                return bundle
            }
            return extBundle
        }

        // Fallback: use Bundle.main (works when running as the main app)
        let mainURL = Bundle.main.bundleURL
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
