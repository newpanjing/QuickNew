import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    var directoryStore: MonitoredDirectoryStore?

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

        NSApp.setActivationPolicy(.accessory)
        for window in NSApp.windows {
            window.orderOut(nil)
        }
        NSApp.activate(ignoringOtherApps: true)

        QuickNewURLHandler.handle(url, directoryStore: directoryStore)

        NSApp.setActivationPolicy(.regular)
        NSApp.hide(nil)
    }
}

@main
struct RightMenuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authorization = AuthorizationStatusStore()
    @StateObject private var directoryStore = MonitoredDirectoryStore()
    @StateObject private var language = LanguageSettingsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authorization)
                .environmentObject(directoryStore)
                .environmentObject(language)
                .id(language.revision)
                .frame(minWidth: 680, minHeight: 500)
                .onReceive(NotificationCenter.default.publisher(for: L10n.languageChangedNotification)) { _ in
                    language.refreshText()
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

@MainActor
enum QuickNewURLHandler {
    static func handle(_ url: URL, directoryStore: MonitoredDirectoryStore?) {
        guard url.scheme == "quicknew", url.host == "create" else { return }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let kindParam = components.queryItems?.first(where: { $0.name == "kind" })?.value,
              let kind = MenuItemKind(rawValue: kindParam),
              let dirParam = components.queryItems?.first(where: { $0.name == "dir" })?.value else { return }

        let directory = URL(fileURLWithPath: dirParam)

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
                directoryStore?.refreshAuthorizedDirectories()
            } catch {
                NSLog("[QuickNew] Bookmark creation failed: \(error)")
            }
            if didAccess { selectedURL.stopAccessingSecurityScopedResource() }
        }

        do {
            let service = FileCreationService(authorizationStore: DirectoryAuthorizationStore.shared)
            let result = try service.create(kind, in: directory)
            NSWorkspace.shared.activateFileViewerSelecting([result.url])
        } catch {
            NSLog("[QuickNew] File creation failed: \(error)")
        }
    }
}
