import Cocoa
import FinderSync

final class FinderSyncController: FIFinderSync {

    // MARK: - Fixed Menu Items (non-editable)

    private static let fixedKinds: [MenuItemKind] = [
        .folder, .text, .markdown, .richText, .word, .excel, .powerpoint, .csv,
    ]

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
            item.representedObject = kind
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

    @objc private func createFile(_ sender: NSMenuItem) {
        guard let kind = sender.representedObject as? MenuItemKind else { return }
        guard let targetDir = resolveTargetDirectory() else {
            NSLog("[QuickNew] Cannot determine target directory")
            return
        }

        var components = URLComponents()
        components.scheme = "quicknew"
        components.host = "create"
        components.queryItems = [
            URLQueryItem(name: "kind", value: kind.rawValue),
            URLQueryItem(name: "dir", value: targetDir.path),
        ]

        guard let url = components.url else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Helpers

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
