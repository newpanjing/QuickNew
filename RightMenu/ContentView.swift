import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authorization: AuthorizationStatusStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                extensionStatusCard

                steps

                supportedTypesCard
            }
            .padding(32)
            .frame(maxWidth: 760, alignment: .leading)
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    authorization.prepareForAuthorization(openSettings: true)
                } label: {
                    Label(L10n.string("toolbar.enable_extension"), systemImage: "switch.2")
                }
                .help(L10n.string("toolbar.enable_extension.help"))

                Button {
                    ExtensionManager.restartFinderExtension()
                } label: {
                    Label(L10n.string("toolbar.restart_finder"), systemImage: "arrow.clockwise")
                }
                .help(L10n.string("toolbar.restart_finder.help"))
            }
        }
        .onAppear {
            authorization.refresh()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppConstants.appDisplayName)
                .font(.largeTitle.weight(.semibold))
            Text(L10n.string("overview.subtitle"))
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var extensionStatusCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: authorization.extensionStatus.systemImageName)
                .font(.title2)
                .foregroundStyle(authorization.isReady ? Color.green : Color.orange)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(L10n.string("auth.card.extension.title"))
                        .font(.headline)
                    Spacer()
                    Text(authorization.extensionStatus.title)
                        .font(.callout)
                        .foregroundStyle(authorization.isReady ? Color.green : Color.secondary)
                }
                Text(authorization.extensionStatus.detail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary)
        }
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.string("auth.steps.title"))
                .font(.headline)
            Text(L10n.string("auth.steps.one"))
            Text(L10n.string("auth.steps.two"))
            Text(L10n.string("auth.steps.three"))
            Text(L10n.string("auth.steps.four"))
        }
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var supportedTypesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.string("menu.settings.items.title"))
                .font(.headline)

            let kinds: [MenuItemKind] = [.folder, .text, .markdown, .richText, .word, .excel, .powerpoint, .csv]
            FlowLayout(spacing: 8) {
                ForEach(kinds) { kind in
                    HStack(spacing: 4) {
                        MenuItemIcon.image(for: kind)
                            .resizable()
                            .frame(width: 16, height: 16)
                        Text(kind.title)
                            .font(.callout)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.background, in: RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.quaternary)
                    }
                }
            }
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
