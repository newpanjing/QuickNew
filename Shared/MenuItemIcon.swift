import AppKit
import SwiftUI
import UniformTypeIdentifiers

enum MenuItemIcon {
    static func nsImage(for kind: MenuItemKind, size: NSSize = NSSize(width: 18, height: 18)) -> NSImage {
        if let url = Bundle.main.url(forResource: kind.iconResourceName, withExtension: "svg"),
           let image = NSImage(contentsOf: url) {
            image.size = size
            image.isTemplate = true
            return image
        }

        let fileExtension = (kind.defaultName as NSString).pathExtension
        let fallback: NSImage
        if let contentType = UTType(filenameExtension: fileExtension) {
            fallback = NSWorkspace.shared.icon(for: contentType)
        } else {
            fallback = NSImage(systemSymbolName: "doc", accessibilityDescription: kind.title) ?? NSImage()
        }
        fallback.size = size
        return fallback
    }

    static func image(for kind: MenuItemKind) -> Image {
        Image(nsImage: nsImage(for: kind, size: NSSize(width: 22, height: 22)))
    }
}
