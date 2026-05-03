import Cocoa
import FinderSync

final class FinderSyncController: FIFinderSync {

    // MARK: - Fixed Menu Items (non-editable)

    private static let fixedKinds: [MenuItemKind] = [
        .folder, .text, .markdown, .richText, .word, .excel, .powerpoint, .csv,
    ]

    private let authStore = DirectoryAuthorizationStore(store: .sharedForExtension)

    // MARK: - Init

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    // MARK: - FIFinderSync

    override func beginObservingDirectory(at url: URL) {
        // No-op
    }

    override func endObservingDirectory(at url: URL) {
        // No-op
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems || menuKind == .contextualMenuForContainer else {
            return nil
        }

        let menu = NSMenu()
        let submenu = NSMenu()

        for kind in Self.fixedKinds {
            let item = NSMenuItem(
                title: kind.title,
                action: #selector(createFile(_:)),
                keyEquivalent: ""
            )
            item.representedObject = kind.rawValue
            item.target = self
            item.image = MenuItemIcon.nsImage(for: kind, size: NSSize(width: 16, height: 16))
            submenu.addItem(item)
        }

        let parentItem = menu.addItem(
            withTitle: L10n.string("finder.menu.new_parent"),
            action: nil,
            keyEquivalent: ""
        )
        parentItem.submenu = submenu

        return menu
    }

    // MARK: - Actions

    @objc func createFile(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let kind = MenuItemKind(rawValue: rawValue) else { return }
        guard let targetDir = resolveTargetDirectory() else { return }

        // Has bookmark → try creating file directly
        if authStore.hasSavedAuthorizationCovering(targetDir) {
            let service = FileCreationService(authorizationStore: authStore)
            do {
                let result = try service.create(kind, in: targetDir)
                NSWorkspace.shared.activateFileViewerSelecting([result.url])
                return
            } catch let error as FileCreationError where error.requiresDirectoryAuthorization {
                // Bookmark is stale or invalid → need to re-authorize via main app
                NSLog("[QuickNew] Authorization stale for %@ — falling back to URL scheme", targetDir.path)
            } catch {
                // Other error → show alert in Finder
                showAlert(title: L10n.string("finder.error.create.title"),
                          message: error.localizedDescription,
                          recovery: (error as? FileCreationError)?.recoverySuggestion)
                return
            }
        }

        // No bookmark or stale bookmark → open URL scheme to main app for authorization
        openURLScheme(kind: kind, directory: targetDir)
    }

    // MARK: - Helpers

    private func openURLScheme(kind: MenuItemKind, directory: URL) {
        guard let url = URL(string: "quicknew://create?kind=\(kind.rawValue)&dir=\(directory.path)") else { return }
        NSLog("[QuickNew] Opening URL scheme: %@", url.absoluteString)
        let opened = NSWorkspace.shared.open(url)
        if !opened {
            // URL scheme failed → show error
            showAlert(title: L10n.string("finder.error.create.title"),
                      message: L10n.string("file.error.permission_required"),
                      recovery: L10n.string("file.error.permission_required.recovery"))
        }
    }

    private func showAlert(title: String, message: String, recovery: String?) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = message
        if let recovery {
            alert.informativeText += "\n\n" + recovery
        }
        alert.addButton(withTitle: L10n.string("common.ok"))
        alert.runModal()
    }

    private func resolveTargetDirectory() -> URL? {
        let controller = FIFinderSyncController.default()

        if let targeted = controller.targetedURL() {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: targeted.path, isDirectory: &isDir), isDir.boolValue {
                return targeted
            }
            return targeted.deletingLastPathComponent()
        }

        if let selected = controller.selectedItemURLs()?.first {
            return selected.deletingLastPathComponent()
        }

        return nil
    }
}
