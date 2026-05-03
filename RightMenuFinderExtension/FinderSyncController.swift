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
            item.representedObject = kind.rawValue
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
        guard let rawValue = sender.representedObject as? String,
              let kind = MenuItemKind(rawValue: rawValue) else {
            NSLog("[QuickNew] Invalid menu item")
            return
        }
        guard let targetDir = resolveTargetDirectory() else {
            NSLog("[QuickNew] Cannot determine target directory")
            return
        }

        let urlStr = "quicknew://create?kind=\(kind.rawValue)&dir=\(targetDir.path)"
        guard let url = URL(string: urlStr) else {
            NSLog("[QuickNew] Failed to create URL")
            return
        }

        NSLog("[QuickNew] Opening URL: \(urlStr)")
        let result = NSWorkspace.shared.open(url)
        NSLog("[QuickNew] NSWorkspace.open result: \(result)")
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
