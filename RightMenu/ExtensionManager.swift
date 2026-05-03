import AppKit
import CoreServices
import FinderSync

enum ExtensionManager {
    @discardableResult
    static func registerFinderExtension() -> Bool {
        LSRegisterURL(Bundle.main.bundleURL as CFURL, true) == noErr
    }

    static func requestFinderExtensionAuthorization() {
        registerFinderExtension()
        openSystemSettings()
    }

    static func openSystemSettings() {
        FIFinderSyncController.showExtensionManagementInterface()
    }

    static func restartFinder() {
    }

    static func restartFinderExtension() {
    }

    static func currentFinderExtensionURL() -> URL? {
        Bundle.main.builtInPlugInsURL?.appendingPathComponent("QuickNewFinderExtension.appex")
    }
}
