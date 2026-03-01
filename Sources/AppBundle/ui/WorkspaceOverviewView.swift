import SwiftUI

public struct WorkspaceOverviewView: View {
    @ObservedObject private var model: WorkspaceOverviewModel

    public init(model: WorkspaceOverviewModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(model.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.primary.opacity(0.9))

            ScrollView {
                VStack(spacing: 6) {
                    ForEach(Array(model.entries.enumerated()), id: \.element.id) { index, entry in
                        HStack(spacing: 8) {
                            Text(entry.name)
                                .font(.system(size: 13, weight: .medium))
                            Spacer(minLength: 8)
                            if entry.isFocused {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 7, height: 7)
                            }
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(index == model.selectedIndex ? Color.accentColor.opacity(0.22) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            model.select(index: index)
                        }
                        .onTapGesture(count: 2) {
                            model.select(index: index)
                            model.submitSelection()
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(width: model.panelSize.width, height: model.panelSize.height)
        .background(.ultraThinMaterial)
    }
}
