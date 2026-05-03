import SwiftUI

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        let event = NSAppleEventManager.shared().currentAppleEvent
        if let event = event,
           event.eventClass == AEEventClass(kInternetEventClass),
           event.eventID == AEEventID(kAEGetURL) {
            NSApp.setActivationPolicy(.accessory)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first, url.scheme == "quicknew" else { return }
        handleQuickNewURL(url)
    }
}

// MARK: - App

@main
struct RightMenuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authorization = AuthorizationStatusStore()
    @StateObject private var language = LanguageSettingsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authorization)
                .environmentObject(language)
                .id(language.revision)
                .frame(minWidth: 680, minHeight: 500)
                .onReceive(NotificationCenter.default.publisher(for: L10n.languageChangedNotification)) { _ in
                    language.refreshText()
                }
                .onOpenURL { url in
                    handleQuickNewURL(url)
                }
        }
        .windowStyle(.hiddenTitleBar)

        Settings {
            SettingsView()
                .environmentObject(language)
                .id(language.revision)
                .frame(width: 520)
                .onReceive(NotificationCenter.default.publisher(for: L10n.languageChangedNotification)) { _ in
                    language.refreshText()
                }
        }
    }
}

// MARK: - URL Handling

@MainActor
private func handleQuickNewURL(_ url: URL) {
    guard url.scheme == "quicknew" else { return }

    NSApp.setActivationPolicy(.accessory)
    for window in NSApp.windows {
        window.orderOut(nil)
    }
    NSApp.activate(ignoringOtherApps: true)

    QuickNewURLHandler.handle(url)

    NSApp.setActivationPolicy(.regular)
    NSApp.hide(nil)
}

// MARK: - URL Handler

@MainActor
enum QuickNewURLHandler {
    static func handle(_ url: URL) {
        guard url.host == "create" else { return }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let kindParam = components.queryItems?.first(where: { $0.name == "kind" })?.value,
              let kind = MenuItemKind(rawValue: kindParam),
              let dirParam = components.queryItems?.first(where: { $0.name == "dir" })?.value else {
            NSLog("[QuickNew] Invalid URL parameters")
            return
        }

        NSLog("[QuickNew] Creating \(kind.rawValue) in \(dirParam)")
        let directory = URL(fileURLWithPath: dirParam)

        // If directory is not yet authorized, prompt once via NSOpenPanel
        if !DirectoryAuthorizationStore.shared.hasSavedAuthorizationCovering(directory) {
            let panel = NSOpenPanel()
            panel.title = AppConstants.appDisplayName
            panel.message = String(format: L10n.string("finder.auth.panel.message"),
                                   directory.lastPathComponent.isEmpty ? directory.path : directory.lastPathComponent)
            panel.prompt = L10n.string("finder.auth.panel.prompt")
            panel.directoryURL = directory
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.allowsMultipleSelection = false
            panel.canCreateDirectories = false

            guard panel.runModal() == .OK, let selectedURL = panel.url else { return }

            let didAccess = selectedURL.startAccessingSecurityScopedResource()
            do {
                let bookmarkData = try selectedURL.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                DirectoryAuthorizationStore.shared.saveBookmarkData(bookmarkData, forPath: selectedURL.path)
            } catch {
                NSLog("[QuickNew] Bookmark creation failed: \(error)")
            }
            if didAccess { selectedURL.stopAccessingSecurityScopedResource() }
        }

        // Create the file
        do {
            let service = FileCreationService(authorizationStore: DirectoryAuthorizationStore.shared)
            let result = try service.create(kind, in: directory)
            NSLog("[QuickNew] Created: \(result.url.path)")
            NSWorkspace.shared.activateFileViewerSelecting([result.url])
        } catch {
            NSLog("[QuickNew] File creation failed: \(error)")
        }
    }
}
