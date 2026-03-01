import AppKit
import Common

struct WorkspaceOverviewCommand: Command {
    let args: WorkspaceOverviewCmdArgs
    /*conforms*/ var shouldResetClosedWindowsCache = false

    @MainActor
    func run(_ env: CmdEnv, _ io: CmdIo) -> Bool {
        let requestedMonitors = resolveRequestedMonitors(io)
        if requestedMonitors.isEmpty {
            return false
        }

        if !args.gui {
            let names = collectWorkspaceNames(monitors: requestedMonitors)
            return io.out(names)
        }

        let monitor: Monitor
        if requestedMonitors.count == 1 {
            monitor = requestedMonitors[0]
        } else {
            io.err("workspace-overview GUI mode requires a single monitor. Falling back to focused monitor")
            monitor = focus.workspace.workspaceMonitor
        }

        let monitorWorkspaceNames = getRelativeWorkspaceCandidates(current: monitor.activeWorkspace, stdin: nil)
        let entries = monitorWorkspaceNames.map {
            WorkspaceOverviewEntry(name: $0.name, isFocused: $0.name == focus.workspace.name)
        }

        let model = WorkspaceOverviewModel(
            title: "Workspaces - \(monitor.name)",
            entries: entries,
            selectedWorkspaceName: monitor.activeWorkspace.name,
            onSelect: { workspaceName in
                _ = Workspace.get(byName: workspaceName).focusWorkspace()
            },
            onClose: {
                WorkspaceOverviewPanel.shared.close()
            }
        )

        WorkspaceOverviewPanel.shared.show(model: model, monitor: monitor)
        return true
    }

    @MainActor
    private func resolveRequestedMonitors(_ io: CmdIo) -> [Monitor] {
        let allMonitors = sortedMonitors
        var result: [Monitor] = []
        var seen: Set<CGPoint> = []

        for monitorId in args.monitorIds {
            let resolved = monitorId.resolve(io, sortedMonitors: allMonitors)
            if resolved.isEmpty {
                return []
            }
            for monitor in resolved {
                if seen.insert(monitor.rect.topLeftCorner).inserted {
                    result.append(monitor)
                }
            }
        }

        return result
    }

    @MainActor
    private func collectWorkspaceNames(monitors: [Monitor]) -> [String] {
        var result: [String] = []
        var seen: Set<String> = []
        for monitor in monitors {
            for workspace in getRelativeWorkspaceCandidates(current: monitor.activeWorkspace, stdin: nil) {
                if seen.insert(workspace.name).inserted {
                    result.append(workspace.name)
                }
            }
        }
        return result
    }
}
