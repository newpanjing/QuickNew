import Foundation

final class MenuPreferences: ObservableObject {
    @Published var enabledItems: Set<MenuItemKind> {
        didSet { save() }
    }

    @Published var useSubmenu: Bool {
        didSet { save() }
    }

    @Published var orderedItems: [MenuItemKind] {
        didSet { save() }
    }

    private let store: PreferencesStore

    init(store: PreferencesStore = .shared) {
        self.store = store
        let hasStoredItems = store.object(forKey: Keys.enabledItems) != nil
        let storedItems = store.stringArray(forKey: Keys.enabledItems) ?? []
        var resolvedItems: Set<MenuItemKind>
        if hasStoredItems {
            resolvedItems = Set(storedItems.compactMap(MenuItemKind.init(rawValue:)))
        } else {
            resolvedItems = Set(MenuItemKind.allCases)
        }
        if !hasStoredItems, store.integer(forKey: Keys.schemaVersion) < 2 {
            resolvedItems.formUnion(MenuItemKind.allCases)
        }
        enabledItems = resolvedItems

        if store.object(forKey: Keys.useSubmenu) == nil {
            useSubmenu = true
        } else {
            useSubmenu = store.bool(forKey: Keys.useSubmenu)
        }
        let storedOrder = store.stringArray(forKey: Keys.itemOrder) ?? []
        let resolvedOrder = storedOrder.compactMap(MenuItemKind.init(rawValue:))
        orderedItems = Self.normalizedOrder(resolvedOrder)
        save()
    }

    func isEnabled(_ kind: MenuItemKind) -> Bool {
        enabledItems.contains(kind)
    }

    func setEnabled(_ isEnabled: Bool, for kind: MenuItemKind) {
        if isEnabled {
            enabledItems.insert(kind)
        } else {
            enabledItems.remove(kind)
        }
    }

    var orderedEnabledItems: [MenuItemKind] {
        orderedItems.filter { enabledItems.contains($0) }
    }

    func moveItems(from source: IndexSet, to destination: Int) {
        orderedItems.move(fromOffsets: source, toOffset: destination)
    }

    private func save() {
        store.set(enabledItems.map(\.rawValue), forKey: Keys.enabledItems)
        store.set(useSubmenu, forKey: Keys.useSubmenu)
        store.set(orderedItems.map(\.rawValue), forKey: Keys.itemOrder)
        store.set(2, forKey: Keys.schemaVersion)
    }

    private static func normalizedOrder(_ storedOrder: [MenuItemKind]) -> [MenuItemKind] {
        var seen = Set<MenuItemKind>()
        var result: [MenuItemKind] = []

        for kind in storedOrder where !seen.contains(kind) {
            result.append(kind)
            seen.insert(kind)
        }

        for kind in MenuItemKind.allCases where !seen.contains(kind) {
            result.append(kind)
        }

        return result
    }

    private enum Keys {
        static let enabledItems = "enabledItems"
        static let useSubmenu = "useSubmenu"
        static let itemOrder = "itemOrder"
        static let schemaVersion = "schemaVersion"
    }
}
