public struct WorkspaceCmdArgs: CmdArgs {
    /*conforms*/ public var commonState: CmdArgsCommonState
    public init(rawArgs: StrArrSlice) { self.commonState = .init(rawArgs) }
    public static let parser: CmdParser<Self> = cmdParser(
        kind: .workspace,
        allowInConfig: true,
        help: workspace_help_generated,
        flags: [
            "--auto-back-and-forth": optionalTrueBoolFlag(\._autoBackAndForth),
            "--wrap-around": optionalTrueBoolFlag(\._wrapAround),
            "--fail-if-noop": trueBoolFlag(\.failIfNoop),

            "--stdin": optionalTrueBoolFlag(\.explicitStdinFlag),
            "--no-stdin": optionalFalseBoolFlag(\.explicitStdinFlag),
        ],
        posArgs: [newArgParser(\.target, parseWorkspaceCmdTarget, mandatoryArgPlaceholder: workspaceCmdTargetPlaceholder)],
        conflictingOptions: [
            ["--stdin", "--no-stdin"],
        ],
    )

    public var target: Lateinit<WorkspaceTarget> = .uninitialized
    public var _autoBackAndForth: Bool?
    public var failIfNoop: Bool = false
    public var _wrapAround: Bool?
    public var explicitStdinFlag: Bool? = nil
}

public func parseWorkspaceCmdArgs(_ args: StrArrSlice) -> ParsedCmd<WorkspaceCmdArgs> {
    parseSpecificCmdArgs(WorkspaceCmdArgs(rawArgs: args), args)
        .filter("--wrapAround requires using \(workspaceCmdRelativeDirectionLiteral) argument") { ($0._wrapAround != nil).implies($0.target.val.isRelatve) }
        .filterNot("--auto-back-and-forth is incompatible with \(workspaceCmdRelativeDirectionLiteral)") { $0._autoBackAndForth != nil && $0.target.val.isRelatve }
        .filterNot("--fail-if-noop is incompatible with \(workspaceCmdRelativeDirectionLiteral)") { $0.failIfNoop && $0.target.val.isRelatve }
        .filterNot("--fail-if-noop is incompatible with --auto-back-and-forth") { $0.autoBackAndForth && $0.failIfNoop }
        .filter("--stdin and --no-stdin require using \(workspaceCmdRelativeDirectionLiteral) argument") { ($0.explicitStdinFlag != nil).implies($0.target.val.isRelatve) }
}

extension WorkspaceCmdArgs {
    public var wrapAround: Bool { _wrapAround ?? false }
    public var autoBackAndForth: Bool { _autoBackAndForth ?? false }
    public var useStdin: Bool { explicitStdinFlag ?? false }
}

public enum WorkspaceTarget: Equatable, Sendable {
    case relative(NextPrev)
    case direct(WorkspaceName)

    var isDirect: Bool { !isRelatve }
    public var isRelatve: Bool {
        switch self {
            case .relative: true
            default: false
        }
    }

    public func workspaceNameOrNil() -> WorkspaceName? {
        switch self {
            case .direct(let name): name
            case .relative: nil
        }
    }
}

let workspaceTargetPlaceholder = "(<workspace-name>|next|prev)"
let workspaceCmdTargetPlaceholder = "(<workspace-name>|next|prev|up|down)"
let workspaceCmdRelativeDirectionLiteral = "(next|prev|up|down)"

func parseWorkspaceCmdTarget(i: ArgParserInput) -> ParsedCliArgs<WorkspaceTarget> {
    switch i.arg {
        case "next", "down": .succ(.relative(.next), advanceBy: 1)
        case "prev", "up": .succ(.relative(.prev), advanceBy: 1)
        default: parseWorkspaceTarget(i: i)
    }
}

func parseWorkspaceTarget(i: ArgParserInput) -> ParsedCliArgs<WorkspaceTarget> {
    switch i.arg {
        case "next": .succ(.relative(.next), advanceBy: 1)
        case "prev": .succ(.relative(.prev), advanceBy: 1)
        default: .init(WorkspaceName.parse(i.arg).map(WorkspaceTarget.direct), advanceBy: 1)
    }
}
