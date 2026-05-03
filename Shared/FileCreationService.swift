import Foundation

enum FileCreationError: LocalizedError {
    case invalidMenuItem
    case missingTargetDirectory
    case targetIsNotDirectory(URL)
    case permissionRequired(URL)
    case permissionStale(URL)
    case cannotAccessDirectory(URL)
    case cannotWriteDirectory(URL)
    case authorizationCouldNotBeSaved(URL)
    case missingTemplate(MenuItemKind)
    case itemWasNotCreated(URL)

    var errorDescription: String? {
        switch self {
        case .invalidMenuItem:
            L10n.string("file.error.invalid_menu_item")
        case .missingTargetDirectory:
            L10n.string("file.error.missing_target_directory")
        case .targetIsNotDirectory(let url):
            String(format: L10n.string("file.error.target_is_not_directory"), url.lastPathComponent)
        case .permissionRequired(let url):
            String(format: L10n.string("file.error.permission_required"), url.path)
        case .permissionStale(let url):
            String(format: L10n.string("file.error.permission_stale"), url.path)
        case .cannotAccessDirectory(let url):
            String(format: L10n.string("file.error.cannot_access_directory"), url.path)
        case .cannotWriteDirectory(let url):
            String(format: L10n.string("file.error.cannot_write_directory"), url.path)
        case .authorizationCouldNotBeSaved(let url):
            String(format: L10n.string("file.error.authorization_could_not_be_saved"), url.path)
        case .missingTemplate(let kind):
            String(format: L10n.string("file.error.missing_template"), kind.title)
        case .itemWasNotCreated(let url):
            String(format: L10n.string("file.error.item_was_not_created"), url.path)
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidMenuItem:
            L10n.string("file.error.invalid_menu_item.recovery")
        case .missingTargetDirectory:
            L10n.string("file.error.missing_target_directory.recovery")
        case .permissionRequired, .permissionStale:
            L10n.string("file.error.permission_required.recovery")
        case .cannotAccessDirectory, .cannotWriteDirectory:
            L10n.string("file.error.cannot_write_directory.recovery")
        case .authorizationCouldNotBeSaved:
            L10n.string("file.error.authorization_could_not_be_saved.recovery")
        case .missingTemplate:
            L10n.string("file.error.missing_template.recovery")
        case .targetIsNotDirectory, .itemWasNotCreated:
            nil
        }
    }

    var requiresDirectoryAuthorization: Bool {
        switch self {
        case .permissionRequired, .permissionStale:
            true
        default:
            false
        }
    }
}

struct FileCreationResult: Equatable {
    let url: URL
    let didCreateDirectory: Bool
}

struct FileCreationService {
    private let fileManager: FileManager
    private let authorizationStore: DirectoryAuthorizationStore?

    init(fileManager: FileManager = .default, authorizationStore: DirectoryAuthorizationStore? = nil) {
        self.fileManager = fileManager
        self.authorizationStore = authorizationStore
    }

    func create(_ kind: MenuItemKind, in directory: URL) throws -> FileCreationResult {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw FileCreationError.targetIsNotDirectory(directory)
        }

        var didAccessSecurityScopedResource = false
        var accessURL: URL?

        if let authorizationStore {
            guard let authorization = authorizationStore.authorization(for: directory) else {
                throw FileCreationError.permissionRequired(directory)
            }
            if authorization.isStale {
                throw FileCreationError.permissionStale(authorization.rootURL)
            }
            accessURL = authorization.accessibleURL
        }

        if let url = accessURL {
            didAccessSecurityScopedResource = url.startAccessingSecurityScopedResource()
        }
        defer {
            if didAccessSecurityScopedResource {
                accessURL?.stopAccessingSecurityScopedResource()
            }
        }

        guard fileManager.isWritableFile(atPath: directory.path) else {
            throw FileCreationError.cannotWriteDirectory(directory)
        }

        let destination = uniqueDestination(for: kind.defaultName, in: directory)
        if kind.isDirectory {
            try fileManager.createDirectory(at: destination, withIntermediateDirectories: false)
        } else if let templateResourceName = kind.templateResourceName,
                  let templateResourceExtension = kind.templateResourceExtension,
                  let templateURL = Bundle.main.url(forResource: templateResourceName, withExtension: templateResourceExtension) {
            try fileManager.copyItem(at: templateURL, to: destination)
        } else {
            guard let contents = kind.defaultContents else {
                throw FileCreationError.missingTemplate(kind)
            }
            try contents.write(to: destination, options: .withoutOverwriting)
        }

        guard fileManager.fileExists(atPath: destination.path) else {
            throw FileCreationError.itemWasNotCreated(destination)
        }
        return FileCreationResult(url: destination, didCreateDirectory: kind.isDirectory)
    }

    private func uniqueDestination(for fileName: String, in directory: URL) -> URL {
        let originalURL = directory.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: originalURL.path) else {
            return originalURL
        }

        let nsName = fileName as NSString
        let baseName = nsName.deletingPathExtension
        let pathExtension = nsName.pathExtension

        var index = 2
        while true {
            let candidateName: String
            if pathExtension.isEmpty {
                candidateName = "\(baseName) \(index)"
            } else {
                candidateName = "\(baseName) \(index).\(pathExtension)"
            }

            let candidate = directory.appendingPathComponent(candidateName)
            if !fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
            index += 1
        }
    }
}
