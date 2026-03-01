@testable import AppBundle
import Common
import XCTest

@MainActor
final class ResizeCommandTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    func testParseCommand() {
        testParseCommandSucc("resize smart +10", ResizeCmdArgs(rawArgs: [], dimension: .smart, units: .add(10)))
        testParseCommandSucc("resize smart -10", ResizeCmdArgs(rawArgs: [], dimension: .smart, units: .subtract(10)))
        testParseCommandSucc("resize smart 10", ResizeCmdArgs(rawArgs: [], dimension: .smart, units: .set(10)))

        testParseCommandSucc("resize smart-opposite +10", ResizeCmdArgs(rawArgs: [], dimension: .smartOpposite, units: .add(10)))
        testParseCommandSucc("resize smart-opposite -10", ResizeCmdArgs(rawArgs: [], dimension: .smartOpposite, units: .subtract(10)))
        testParseCommandSucc("resize smart-opposite 10", ResizeCmdArgs(rawArgs: [], dimension: .smartOpposite, units: .set(10)))

        testParseCommandSucc("resize height 10", ResizeCmdArgs(rawArgs: [], dimension: .height, units: .set(10)))
        testParseCommandSucc("resize width 10", ResizeCmdArgs(rawArgs: [], dimension: .width, units: .set(10)))

        testParseCommandFail("resize s 10", msg: """
            ERROR: Can't parse 's'.
                   Possible values: (width|height|smart|smart-opposite)
            """)
        testParseCommandFail("resize smart foo", msg: "ERROR: <number> argument must be a number")
    }

    func testResizeInScrollLayoutUpdatesMainRatio() async throws {
        let root = Workspace.get(byName: name).rootTilingContainer
        root.layout = .scroll
        _ = TestWindow.new(id: 1, parent: root).focusWindow()

        let result = try await ResizeCommand(args: ResizeCmdArgs(rawArgs: [], dimension: .smart, units: .add(10)))
            .run(.defaultEnv, .emptyStdin)
        assertEquals(result.exitCode, 0)
        XCTAssertEqual(Double(root.scrollMainPaneRatio ?? 0), 0.905, accuracy: 0.0001)
    }

    func testResizeSmartOppositeInScrollLayoutFails() async throws {
        let root = Workspace.get(byName: name).rootTilingContainer
        root.layout = .scroll
        _ = TestWindow.new(id: 1, parent: root).focusWindow()

        let result = try await ResizeCommand(args: ResizeCmdArgs(rawArgs: [], dimension: .smartOpposite, units: .add(10)))
            .run(.defaultEnv, .emptyStdin)
        assertEquals(result.exitCode, 1)
        assertEquals(result.stderr, ["resize smart-opposite is unsupported in scroll layout"])
    }

    func testResizeWidthInVScrollLayoutFails() async throws {
        let root = Workspace.get(byName: name).rootTilingContainer
        root.layout = .scroll
        root.changeOrientation(.v)
        _ = TestWindow.new(id: 1, parent: root).focusWindow()

        let result = try await ResizeCommand(args: ResizeCmdArgs(rawArgs: [], dimension: .width, units: .add(10)))
            .run(.defaultEnv, .emptyStdin)
        assertEquals(result.exitCode, 1)
        assertEquals(result.stderr, ["resize width is incompatible with v_scroll"])
    }
}
