import SwiftUI

struct DirectoryManagementView: View {
    @EnvironmentObject private var directoryStore: MonitoredDirectoryStore

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    ForEach(directoryStore.authorizedDirectories, id: \.self) { url in
                        authorizationRow(url)
                    }
                } header: {
                    Text(L10n.string("directory.section.authorized"))
                }

                Section {
                    ForEach(directoryStore.directories, id: \.self) { url in
                        monitoredRow(url)
                    }
                } header: {
                    Text(L10n.string("directory.section.monitored"))
                }
            }

            Divider()

            HStack {
                Button {
                    directoryStore.addDirectoryUsingPanel()
                } label: {
                    Label(L10n.string("directory.button.add"), systemImage: "plus")
                }

                Button {
                    directoryStore.resetDefaults()
                } label: {
                    Label(L10n.string("directory.button.reset"), systemImage: "arrow.counterclockwise")
                }

                Button {
                    directoryStore.refreshAuthorizedDirectories()
                } label: {
                    Label(L10n.string("directory.button.refresh"), systemImage: "arrow.clockwise")
                }

                Spacer()

                Text(L10n.string("directory.note.restart_finder"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle(L10n.string("nav.locations"))
        .onAppear {
            directoryStore.refreshAuthorizedDirectories()
        }
    }

    private func authorizationRow(_ url: URL) -> some View {
        HStack(spacing: 10) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent)
                Text(url.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Button {
                directoryStore.remove(url)
            } label: {
                Label(L10n.string("directory.button.remove"), systemImage: "minus.circle")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .help(L10n.string("directory.help.remove"))
        }
        .padding(.vertical, 4)
    }

    private func monitoredRow(_ url: URL) -> some View {
        HStack(spacing: 10) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent)
                Text(url.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
