import AppKit
import Foundation

@MainActor
final class MonitoredDirectoryStore: ObservableObject {
    @Published private(set) var directories: [URL] = [] {
        didSet { save() }
    }
    @Published private(set) var authorizedDirectories: [URL] = []

    private let store: PreferencesStore
    private let authorizationStore: DirectoryAuthorizationStore
    private let key = "monitoredDirectoryPaths"

    init(store: PreferencesStore = .shared, authorizationStore: DirectoryAuthorizationStore = .shared) {
        self.store = store
        self.authorizationStore = authorizationStore
    }

    func loadStoredDirectories() {
        let stored = store.stringArray(forKey: key) ?? []
        directories = stored.map(URL.init(fileURLWithPath:))
    }

    func addDirectoryUsingPanel() {
        let panel = NSOpenPanel()
        panel.title = L10n.string("directory.panel.title")
        panel.message = L10n.string("directory.panel.message")
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK else { return }
        add(panel.urls)
    }

    func add(_ urls: [URL]) {
        let saved = authorizationStore.saveAuthorizations(for: urls)
        let merged = directories + urls
        directories = Array(Set(merged)).sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
        if saved.isEmpty {
            refreshAuthorizedDirectories()
        } else {
            authorizedDirectories = authorizationStore.authorizedDirectoryURLs
        }
    }

    func remove(_ url: URL) {
        authorizationStore.removeAuthorization(for: url)
        directories.removeAll { $0 == url }
        refreshAuthorizedDirectories()
    }

    func resetDefaults() {
        let merged = directories + Self.defaultDirectories
        directories = Array(Set(merged)).sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
        refreshAuthorizedDirectories()
    }

    func refreshAuthorizedDirectories() {
        authorizedDirectories = authorizationStore.authorizedDirectoryURLs
    }

    private func save() {
        store.set(directories.map(\.path), forKey: key)
    }

    private static var defaultDirectories: [URL] {
        PreferencesStore.defaultUserDirectories
    }
}
