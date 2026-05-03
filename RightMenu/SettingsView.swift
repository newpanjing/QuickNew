import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var languageStore: LanguageSettingsStore

    var body: some View {
        Form {
            Picker(L10n.string("language.picker.title"), selection: $languageStore.language) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.title).tag(language)
                }
            }
            .pickerStyle(.radioGroup)

            Text(L10n.string("language.picker.footer"))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .padding(24)
    }
}
