import Foundation
import Darwin

final class PreferencesStore: @unchecked Sendable {
    static let shared = PreferencesStore()

    private let defaults: UserDefaults
    /// Shared UserDefaults for menu preferences (read by extension)
    private let sharedDefaults: UserDefaults?
    private let lock = NSLock()

    /// Main app: writes to standard UserDefaults AND shared container
    /// Extension: reads from shared container
    init() {
        self.defaults = .standard
        self.sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        self.sharedDefaults = nil
    }

    init(url: URL) {
        // Use full path hash to ensure unique suite names per test instance
        let suiteName = "test.\(abs(url.path.hashValue))"
        self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
        self.sharedDefaults = nil
    }

    func object(forKey key: String) -> Any? {
        lock.lock()
        defer { lock.unlock() }
        return defaults.object(forKey: key)
    }

    func bool(forKey key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return defaults.bool(forKey: key)
    }

    func integer(forKey key: String) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return defaults.integer(forKey: key)
    }

    func stringArray(forKey key: String) -> [String]? {
        lock.lock()
        defer { lock.unlock() }
        return defaults.stringArray(forKey: key)
    }

    func set(_ value: Any, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        defaults.set(value, forKey: key)
        defaults.synchronize()
        // Sync menu preferences to shared container for extension to read
        sharedDefaults?.set(value, forKey: key)
        sharedDefaults?.synchronize()
    }

    func reload() {
    }

    /// Read menu preferences from shared container (used by extension)
    static var sharedForExtension: PreferencesStore {
        let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) ?? .standard
        return PreferencesStore(defaults: sharedDefaults)
    }

    static var realUserHomeDirectory: URL {
        if let passwd = getpwuid(getuid()),
           let home = passwd.pointee.pw_dir {
            return URL(fileURLWithPath: String(cString: home), isDirectory: true)
        }

        if let home = NSHomeDirectoryForUser(NSUserName()) {
            return URL(fileURLWithPath: home, isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
    }

    static var defaultUserDirectories: [URL] {
        let home = realUserHomeDirectory
        return [
            home,
            home.appendingPathComponent("Desktop", isDirectory: true),
            home.appendingPathComponent("Downloads", isDirectory: true),
            home.appendingPathComponent("Documents", isDirectory: true)
        ]
    }
}
