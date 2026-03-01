public struct WorkspaceOverviewCmdArgs: CmdArgs {
    /*conforms*/ public var commonState: CmdArgsCommonState
    public init(rawArgs: StrArrSlice) { self.commonState = .init(rawArgs) }
    public static let parser: CmdParser<Self> = cmdParser(
        kind: .workspaceOverview,
        allowInConfig: true,
        help: workspace_overview_help_generated,
        flags: [
            "--monitor": SubArgParser(\._monitorIds, parseMonitorIds),
            "--no-gui": falseBoolFlag(\.gui),
        ],
        posArgs: [],
    )

    public var _monitorIds: [MonitorId] = []
    public var gui: Bool = true
}

extension WorkspaceOverviewCmdArgs {
    public var monitorIds: [MonitorId] {
        _monitorIds.isEmpty ? [.focused] : _monitorIds
    }
}

public func parseWorkspaceOverviewCmdArgs(_ args: StrArrSlice) -> ParsedCmd<WorkspaceOverviewCmdArgs> {
    parseSpecificCmdArgs(WorkspaceOverviewCmdArgs(rawArgs: args), args)
}
