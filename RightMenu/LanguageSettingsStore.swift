import Foundation

@MainActor
final class LanguageSettingsStore: ObservableObject {
    @Published var language: AppLanguage {
        didSet {
            guard oldValue != language else { return }
            L10n.setLanguage(language)
        }
    }

    @Published private(set) var revision = UUID()

    init() {
        language = L10n.currentLanguage
    }

    func refreshText() {
        revision = UUID()
    }
}
