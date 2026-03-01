import AppKit
import Common

struct ResizeCommand: Command { // todo cover with tests
    let args: ResizeCmdArgs
    /*conforms*/ var shouldResetClosedWindowsCache = true

    func run(_ env: CmdEnv, _ io: CmdIo) -> Bool {
        guard let target = args.resolveTargetOrReportError(env, io) else { return false }
        let scrollCandidates = target.windowOrNil?.parentsWithSelf
            .filter { ($0.parent as? TilingContainer)?.layout == .scroll } ?? []
        if let scrollNode = scrollCandidates.first,
           let scrollContainer = scrollNode.parent as? TilingContainer
        {
            return resizeInScrollLayout(scrollContainer, args: args, io: io)
        }

        let candidates = target.windowOrNil?.parentsWithSelf
            .filter { ($0.parent as? TilingContainer)?.layout == .tiles }
            ?? []

        let orientation: Orientation?
        let parent: TilingContainer?
        let node: TreeNode?
        switch args.dimension.val {
            case .width:
                orientation = .h
                node = candidates.first(where: { ($0.parent as? TilingContainer)?.orientation == orientation })
                parent = node?.parent as? TilingContainer
            case .height:
                orientation = .v
                node = candidates.first(where: { ($0.parent as? TilingContainer)?.orientation == orientation })
                parent = node?.parent as? TilingContainer
            case .smart:
                node = candidates.first
                parent = node?.parent as? TilingContainer
                orientation = parent?.orientation
            case .smartOpposite:
                orientation = (candidates.first?.parent as? TilingContainer)?.orientation.opposite
                node = candidates.first(where: { ($0.parent as? TilingContainer)?.orientation == orientation })
                parent = node?.parent as? TilingContainer
        }
        guard let parent else { return io.err("resize command doesn't support floating windows yet https://github.com/nikitabobko/AeroSpace/issues/9") }
        guard let orientation else { return false }
        guard let node else { return false }
        let diff: CGFloat = switch args.units.val {
            case .set(let unit): CGFloat(unit) - node.getWeight(orientation)
            case .add(let unit): CGFloat(unit)
            case .subtract(let unit): -CGFloat(unit)
        }

        guard let childDiff = diff.div(parent.children.count - 1) else { return false }
        parent.children.lazy
            .filter { $0 != node }
            .forEach { $0.setWeight(parent.orientation, $0.getWeight(parent.orientation) - childDiff) }

        node.setWeight(orientation, node.getWeight(orientation) + diff)
        return true
    }
}

@MainActor
private func resizeInScrollLayout(_ container: TilingContainer, args: ResizeCmdArgs, io: CmdIo) -> Bool {
    let ratioRange: ClosedRange<CGFloat> = 0.5 ... 1.0

    switch args.dimension.val {
        case .smart:
            break
        case .smartOpposite:
            return io.err("resize smart-opposite is unsupported in scroll layout")
        case .width:
            guard container.orientation == .h else { return io.err("resize width is incompatible with v_scroll") }
        case .height:
            guard container.orientation == .v else { return io.err("resize height is incompatible with h_scroll") }
    }

    let currentRatio = (container.scrollMainPaneRatio ?? CGFloat(config.scrollMainPaneRatio)).coerceIn(ratioRange)
    let step = CGFloat(config.scrollMainPaneRatioStep)
    let newRatio: CGFloat = switch args.units.val {
        case .set(let unit):
            CGFloat(unit) / 100
        case .add(let unit):
            currentRatio + CGFloat(unit) * step / 100
        case .subtract(let unit):
            currentRatio - CGFloat(unit) * step / 100
    }
    container.scrollMainPaneRatio = newRatio.coerceIn(ratioRange)
    return true
}
