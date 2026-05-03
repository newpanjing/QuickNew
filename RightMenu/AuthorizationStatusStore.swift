import FinderSync
import Foundation

@MainActor
final class AuthorizationStatusStore: ObservableObject {
    @Published private(set) var extensionStatus: FinderExtensionStatus = .unknown
    @Published private(set) var lastCheckedAt: Date?
    @Published private(set) var didAttemptRegistration = false
    @Published private(set) var activeExtensionPath: String?
    @Published private(set) var duplicateExtensionCount = 0

    var isReady: Bool {
        extensionStatus == .enabled && duplicateExtensionCount <= 1
    }

    func prepareForAuthorization(openSettings: Bool = false) {
        didAttemptRegistration = ExtensionManager.registerFinderExtension()
        refresh()
        if openSettings {
            ExtensionManager.openSystemSettings()
        }
    }

    func refresh() {
        let snapshot = Self.readFinderExtensionStatus()
        let oldStatus = extensionStatus
        extensionStatus = snapshot.status
        activeExtensionPath = snapshot.activePath
        duplicateExtensionCount = snapshot.matchCount
        lastCheckedAt = Date()

        if oldStatus != .enabled, extensionStatus == .enabled {
            ExtensionManager.restartFinderExtension()
        }
    }

    private static func readFinderExtensionStatus() -> FinderExtensionSnapshot {
        let status: FinderExtensionStatus = FIFinderSyncController.isExtensionEnabled ? .enabled : .disabled
        return FinderExtensionSnapshot(
            status: status,
            activePath: ExtensionManager.currentFinderExtensionURL()?.path,
            matchCount: 1
        )
    }
}

private struct FinderExtensionSnapshot {
    let status: FinderExtensionStatus
    let activePath: String?
    let matchCount: Int
}

enum FinderExtensionStatus: Equatable {
    case unknown
    case notRegistered
    case registered
    case disabled
    case enabled

    var title: String {
        switch self {
        case .unknown: L10n.string("auth.extension.unknown.title")
        case .notRegistered: L10n.string("auth.extension.not_registered.title")
        case .registered: L10n.string("auth.extension.registered.title")
        case .disabled: L10n.string("auth.extension.disabled.title")
        case .enabled: L10n.string("auth.extension.enabled.title")
        }
    }

    var detail: String {
        switch self {
        case .unknown:
            L10n.string("auth.extension.unknown.detail")
        case .notRegistered:
            L10n.string("auth.extension.not_registered.detail")
        case .registered:
            L10n.string("auth.extension.registered.detail")
        case .disabled:
            L10n.string("auth.extension.disabled.detail")
        case .enabled:
            L10n.string("auth.extension.enabled.detail")
        }
    }

    var systemImageName: String {
        switch self {
        case .enabled: "checkmark.circle.fill"
        case .registered: "questionmark.circle.fill"
        case .unknown: "exclamationmark.circle.fill"
        case .notRegistered, .disabled: "xmark.circle.fill"
        }
    }
}
