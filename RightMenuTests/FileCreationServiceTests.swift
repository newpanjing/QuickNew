import XCTest
@testable import RightMenu

final class FileCreationServiceTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: temporaryDirectory)
    }

    // MARK: - Bookmark Persistence Tests

    func testBookmarkSaveAndRead() throws {
        let storeURL = temporaryDirectory.appendingPathComponent("Preferences.plist")
        let preferencesStore = PreferencesStore(url: storeURL)
        let authStore = DirectoryAuthorizationStore(store: preferencesStore)

        // Save authorization
        let saved = authStore.saveAuthorizations(for: [temporaryDirectory])
        XCTAssertEqual(saved.count, 1, "Bookmark should be saved successfully")

        // Verify it's covered
        XCTAssertTrue(authStore.hasSavedAuthorizationCovering(temporaryDirectory),
                       "Directory should be covered after saving bookmark")

        // Verify it persists through a new store instance
        let authStore2 = DirectoryAuthorizationStore(store: PreferencesStore(url: storeURL))
        XCTAssertTrue(authStore2.hasSavedAuthorizationCovering(temporaryDirectory),
                       "Bookmark should persist across store instances")

        // Verify subdirectory is covered
        let subdir = temporaryDirectory.appendingPathComponent("SubDir", isDirectory: true)
        XCTAssertTrue(authStore.hasSavedAuthorizationCovering(subdir),
                       "Subdirectory should be covered by parent bookmark")
    }

    func testBookmarkResolutionAndFileCreation() throws {
        let storeURL = temporaryDirectory.appendingPathComponent("Preferences.plist")
        let preferencesStore = PreferencesStore(url: storeURL)
        let authStore = DirectoryAuthorizationStore(store: preferencesStore)

        let saved = authStore.saveAuthorizations(for: [temporaryDirectory])
        XCTAssertFalse(saved.isEmpty, "Bookmark creation must succeed")

        // Verify authorization can be resolved
        let auth = authStore.authorization(for: temporaryDirectory)
        XCTAssertNotNil(auth, "Bookmark should be resolvable")
        XCTAssertFalse(auth!.isStale, "Bookmark should not be stale")

        // Verify file creation works using the bookmark
        let service = FileCreationService(authorizationStore: authStore)
        let result = try service.create(.text, in: temporaryDirectory)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.url.path),
                       "File should be created using bookmark authorization")
    }

    func testSaveBookmarkDataDirectly() throws {
        let storeURL = temporaryDirectory.appendingPathComponent("Preferences.plist")
        let preferencesStore = PreferencesStore(url: storeURL)
        let authStore = DirectoryAuthorizationStore(store: preferencesStore)

        // Create bookmark data directly
        let bookmarkData = try temporaryDirectory.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        XCTAssertGreaterThan(bookmarkData.count, 0, "Bookmark data should not be empty")

        // Save using direct method
        authStore.saveBookmarkData(bookmarkData, forPath: temporaryDirectory.path)

        // Verify
        XCTAssertTrue(authStore.hasSavedAuthorizationCovering(temporaryDirectory))

        // Verify persistence
        let authStore2 = DirectoryAuthorizationStore(store: PreferencesStore(url: storeURL))
        XCTAssertTrue(authStore2.hasSavedAuthorizationCovering(temporaryDirectory))
    }

    // MARK: - File Creation Tests

    func testCreatesFolderWithUniqueName() throws {
        let service = authorizedService()

        let first = try service.create(.folder, in: temporaryDirectory)
        let second = try service.create(.folder, in: temporaryDirectory)

        XCTAssertEqual(first.url.lastPathComponent, "未命名文件夹")
        XCTAssertEqual(second.url.lastPathComponent, "未命名文件夹 2")
        XCTAssertTrue(first.didCreateDirectory)
    }

    func testCreatesMarkdownTemplate() throws {
        let service = authorizedService()

        let result = try service.create(.markdown, in: temporaryDirectory)
        let contents = try String(contentsOf: result.url, encoding: .utf8)

        XCTAssertEqual(result.url.lastPathComponent, "未命名.md")
        XCTAssertEqual(contents, "# 未命名\n")
        XCTAssertFalse(result.didCreateDirectory)
    }

    func testCreatesTextWithUniqueName() throws {
        let service = authorizedService()

        _ = try service.create(.text, in: temporaryDirectory)
        let result = try service.create(.text, in: temporaryDirectory)

        XCTAssertEqual(result.url.lastPathComponent, "未命名 2.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.url.path))
    }

    func testCreatesCommonTextFormats() throws {
        let service = authorizedService()

        let json = try service.create(.json, in: temporaryDirectory)
        let html = try service.create(.html, in: temporaryDirectory)
        let swift = try service.create(.swift, in: temporaryDirectory)

        XCTAssertEqual(json.url.pathExtension, "json")
        XCTAssertEqual(html.url.pathExtension, "html")
        XCTAssertEqual(swift.url.pathExtension, "swift")
        XCTAssertTrue(try String(contentsOf: json.url, encoding: .utf8).contains("{"))
        XCTAssertTrue(try String(contentsOf: html.url, encoding: .utf8).contains("<!doctype html>"))
        XCTAssertTrue(try String(contentsOf: swift.url, encoding: .utf8).contains("import Foundation"))
    }

    func testCreatesOfficeTemplates() throws {
        let service = authorizedService()

        let word = try service.create(.word, in: temporaryDirectory)
        let excel = try service.create(.excel, in: temporaryDirectory)
        let powerpoint = try service.create(.powerpoint, in: temporaryDirectory)

        XCTAssertEqual(word.url.pathExtension, "docx")
        XCTAssertEqual(excel.url.pathExtension, "xlsx")
        XCTAssertEqual(powerpoint.url.pathExtension, "pptx")
        XCTAssertTrue(isZipFile(word.url))
        XCTAssertTrue(isZipFile(excel.url))
        XCTAssertTrue(isZipFile(powerpoint.url))
    }

    func testCreatesEveryMenuItemKind() throws {
        let service = authorizedService()

        for kind in MenuItemKind.allCases {
            let result = try service.create(kind, in: temporaryDirectory)
            var isDirectory: ObjCBool = false

            XCTAssertTrue(FileManager.default.fileExists(atPath: result.url.path, isDirectory: &isDirectory), "Missing created item for \(kind.rawValue)")
            XCTAssertEqual(isDirectory.boolValue, kind.isDirectory, "Unexpected directory flag for \(kind.rawValue)")
            XCTAssertEqual(result.didCreateDirectory, kind.isDirectory, "Unexpected result flag for \(kind.rawValue)")
        }
    }

    func testMenuPreferencesPersistOnlyCheckedItems() {
        let preferencesURL = temporaryDirectory.appendingPathComponent("Preferences.plist")
        let store = PreferencesStore(url: preferencesURL)
        let preferences = MenuPreferences(store: store)

        MenuItemKind.allCases.forEach { preferences.setEnabled(false, for: $0) }
        preferences.setEnabled(true, for: .markdown)
        preferences.setEnabled(true, for: .text)
        preferences.useSubmenu = false

        let reloaded = MenuPreferences(store: PreferencesStore(url: preferencesURL))
        XCTAssertEqual(reloaded.enabledItems, [.markdown, .text])
        XCTAssertEqual(reloaded.orderedEnabledItems.filter { [.markdown, .text].contains($0) }, [.markdown, .text])
        XCTAssertFalse(reloaded.useSubmenu)
        XCTAssertTrue(reloaded.isEnabled(.markdown))
        XCTAssertTrue(reloaded.isEnabled(.text))
        XCTAssertFalse(reloaded.isEnabled(.folder))
        XCTAssertFalse(reloaded.isEnabled(.word))
    }

    func testFinderMenuReadsOnlyEnabledItemsFromSharedStore() {
        let preferencesURL = temporaryDirectory.appendingPathComponent("Preferences.plist")
        let appPreferences = MenuPreferences(store: PreferencesStore(url: preferencesURL))

        MenuItemKind.allCases.forEach { appPreferences.setEnabled(false, for: $0) }
        appPreferences.setEnabled(true, for: .markdown)
        appPreferences.setEnabled(true, for: .excel)

        let finderPreferences = MenuPreferences(store: PreferencesStore(url: preferencesURL))
        XCTAssertEqual(finderPreferences.orderedEnabledItems, [.markdown, .excel])
    }

    func testMenuPreferencesPersistEmptySelection() {
        let preferencesURL = temporaryDirectory.appendingPathComponent("Preferences.plist")
        let preferences = MenuPreferences(store: PreferencesStore(url: preferencesURL))

        MenuItemKind.allCases.forEach { preferences.setEnabled(false, for: $0) }

        let reloaded = MenuPreferences(store: PreferencesStore(url: preferencesURL))
        XCTAssertTrue(reloaded.enabledItems.isEmpty)
    }

    func testMenuPreferencesPersistItemOrder() {
        let preferencesURL = temporaryDirectory.appendingPathComponent("Preferences.plist")
        let preferences = MenuPreferences(store: PreferencesStore(url: preferencesURL))

        let markdownIndex = preferences.orderedItems.firstIndex(of: .markdown)!
        preferences.moveItems(from: IndexSet(integer: markdownIndex), to: 0)

        let reloaded = MenuPreferences(store: PreferencesStore(url: preferencesURL))
        XCTAssertEqual(reloaded.orderedItems.first, .markdown)
        XCTAssertEqual(reloaded.orderedEnabledItems.first, .markdown)
    }

    func testCustomPreferencesStoreDoesNotLoadUserDefaults() {
        let preferencesURL = temporaryDirectory.appendingPathComponent("MissingPreferences.plist")
        let preferences = MenuPreferences(store: PreferencesStore(url: preferencesURL))

        XCTAssertEqual(preferences.enabledItems, Set(MenuItemKind.allCases))
        XCTAssertEqual(preferences.orderedItems, MenuItemKind.allCases)
    }

    func testThrowsWhenDirectoryAuthorizationDoesNotMatch() {
        let preferencesURL = temporaryDirectory.appendingPathComponent("Preferences.plist")
        let store = PreferencesStore(url: preferencesURL)
        let authorizationStore = DirectoryAuthorizationStore(store: store)
        let otherDirectory = temporaryDirectory.appendingPathComponent("Other", isDirectory: true)
        try? FileManager.default.createDirectory(at: otherDirectory, withIntermediateDirectories: true)
        authorizationStore.saveAuthorizations(for: [otherDirectory])
        let service = FileCreationService(authorizationStore: authorizationStore)

        XCTAssertThrowsError(try service.create(.text, in: temporaryDirectory)) { error in
            guard case FileCreationError.permissionRequired(let url) = error else {
                return XCTFail("Expected permissionRequired, got \(error)")
            }
            XCTAssertEqual(url, temporaryDirectory)
        }
    }

    private func isZipFile(_ url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url), data.count >= 4 else {
            return false
        }
        return data.starts(with: [0x50, 0x4B, 0x03, 0x04])
    }

    private func authorizedService() -> FileCreationService {
        let storeURL = temporaryDirectory.appendingPathComponent("Preferences.plist")
        let preferencesStore = PreferencesStore(url: storeURL)
        let authorizationStore = DirectoryAuthorizationStore(store: preferencesStore)
        authorizationStore.saveAuthorizations(for: [temporaryDirectory])
        return FileCreationService(authorizationStore: authorizationStore)
    }
}
