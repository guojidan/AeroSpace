import CoreGraphics
import Common
import SwiftUI

public struct WorkspaceOverviewEntry: Identifiable, Equatable, Sendable {
    public let name: String
    public let isFocused: Bool

    public var id: String { name }
}

@MainActor
public final class WorkspaceOverviewModel: ObservableObject {
    @Published public private(set) var entries: [WorkspaceOverviewEntry]
    @Published public private(set) var selectedIndex: Int

    public let title: String

    private let onSelect: @MainActor @Sendable (String) -> Void
    private let onClose: @MainActor @Sendable () -> Void

    public init(
        title: String,
        entries: [WorkspaceOverviewEntry],
        selectedWorkspaceName: String?,
        onSelect: @escaping @MainActor @Sendable (String) -> Void,
        onClose: @escaping @MainActor @Sendable () -> Void
    ) {
        self.title = title
        self.entries = entries
        self.onSelect = onSelect
        self.onClose = onClose

        if let selectedWorkspaceName,
           let index = entries.firstIndex(where: { $0.name == selectedWorkspaceName })
        {
            self.selectedIndex = index
        } else {
            self.selectedIndex = 0
        }
    }

    public var panelSize: CGSize {
        let rows = max(entries.count, 1)
        let height = CGFloat(min(rows, 10)) * 34 + 64
        return CGSize(width: 360, height: max(height, 140))
    }

    public func moveUp() {
        guard !entries.isEmpty else { return }
        selectedIndex = selectedIndex == 0 ? entries.count - 1 : selectedIndex - 1
    }

    public func moveDown() {
        guard !entries.isEmpty else { return }
        selectedIndex = selectedIndex == entries.count - 1 ? 0 : selectedIndex + 1
    }

    public func close() {
        onClose()
    }

    public func submitSelection() {
        guard let selected = selectedEntry else {
            close()
            return
        }
        onSelect(selected.name)
        close()
    }

    public func select(index: Int) {
        guard entries.indices.contains(index) else { return }
        selectedIndex = index
    }

    public var selectedEntry: WorkspaceOverviewEntry? {
        entries.getOrNil(atIndex: selectedIndex)
    }
}
