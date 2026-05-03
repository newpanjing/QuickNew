import Foundation

struct DirectoryAuthorization: Equatable {
    let rootURL: URL
    let accessibleURL: URL
    let isStale: Bool
}

final class DirectoryAuthorizationStore: @unchecked Sendable {
    static let shared = DirectoryAuthorizationStore()

    private let store: PreferencesStore
    private let key = "directoryBookmarks"
    private let automaticallySeededDefaultsCleanupKey = "didCleanupAutomaticallySeededDefaultBookmarks"

    init(store: PreferencesStore = .shared) {
        self.store = store
    }

    var hasSavedAuthorizations: Bool {
        return !(store.object(forKey: key) as? [String: Data] ?? [:]).isEmpty
    }

    var authorizedDirectoryURLs: [URL] {
        let bookmarks = store.object(forKey: key) as? [String: Data] ?? [:]
        return bookmarks.keys
            .map { URL(fileURLWithPath: $0, isDirectory: true) }
            .sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
    }

    func hasSavedAuthorizationCovering(_ directory: URL) -> Bool {
        let bookmarks = store.object(forKey: key) as? [String: Data] ?? [:]
        let directoryPath = directory.path
        return bookmarks.keys.contains { rootPath in
            directoryPath == rootPath || directoryPath.hasPrefix(rootPath + "/")
        }
    }

    @discardableResult
    func saveAuthorizations(for urls: [URL]) -> [URL] {
        var bookmarks = store.object(forKey: key) as? [String: Data] ?? [:]
        var savedURLs: [URL] = []
        for url in urls {
            do {
                let didAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if didAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                let bookmark = try url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                bookmarks[url.path] = bookmark
                savedURLs.append(url)
            } catch {
            }
        }
        store.set(bookmarks, forKey: key)
        return savedURLs
    }

    func removeAuthorization(for url: URL) {
        var bookmarks = store.object(forKey: key) as? [String: Data] ?? [:]
        bookmarks.removeValue(forKey: url.path)
        store.set(bookmarks, forKey: key)
    }

    /// Save a pre-created bookmark data directly (avoids re-creating from URL)
    func saveBookmarkData(_ data: Data, forPath path: String) {
        var bookmarks = store.object(forKey: key) as? [String: Data] ?? [:]
        bookmarks[path] = data
        store.set(bookmarks, forKey: key)
    }

    func authorization(for directory: URL) -> DirectoryAuthorization? {
        let bookmarks = store.object(forKey: key) as? [String: Data] ?? [:]
        let directoryPath = directory.path

        let matchingPaths = bookmarks.keys
            .filter { directoryPath == $0 || directoryPath.hasPrefix($0 + "/") }
            .sorted { $0.count > $1.count }

        for path in matchingPaths {
            guard let bookmark = bookmarks[path] else { continue }
            var isStale = false
            if let resolvedURL = try? URL(
                resolvingBookmarkData: bookmark,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) {
                return DirectoryAuthorization(rootURL: URL(fileURLWithPath: path, isDirectory: true), accessibleURL: resolvedURL, isStale: isStale)
            }
        }

        return nil
    }

    func removeInvalidAuthorizations() {
        _ = validBookmarks()
    }

    func removeAutomaticallySeededDefaultAuthorizationsIfNeeded(defaultDirectories: [URL]) {
        if store.bool(forKey: automaticallySeededDefaultsCleanupKey) {
            return
        }

        var bookmarks = store.object(forKey: key) as? [String: Data] ?? [:]
        let defaultPaths = Set(defaultDirectories.map { $0.path })
        let removedPaths = defaultPaths.filter { bookmarks.removeValue(forKey: $0) != nil }

        store.set(bookmarks, forKey: key)
        store.set(true, forKey: automaticallySeededDefaultsCleanupKey)

        if !removedPaths.isEmpty {
        }
    }

    private func validBookmarks() -> [String: Data] {
        var bookmarks = store.object(forKey: key) as? [String: Data] ?? [:]
        var removedPaths: [String] = []

        for (path, bookmark) in bookmarks {
            var isStale = false
            do {
                _ = try URL(
                    resolvingBookmarkData: bookmark,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                if isStale {
                    bookmarks.removeValue(forKey: path)
                    removedPaths.append(path)
                }
            } catch {
                bookmarks.removeValue(forKey: path)
                removedPaths.append(path)
            }
        }

        if !removedPaths.isEmpty {
            store.set(bookmarks, forKey: key)
        }

        return bookmarks
    }
}
