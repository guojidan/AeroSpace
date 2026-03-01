@testable import AppBundle
import Common
import XCTest

@MainActor
final class LayoutCommandTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    func testParseCommand() {
        testParseCommandSucc("layout h_scroll", LayoutCmdArgs(rawArgs: [], toggleBetween: [.h_scroll]))
        testParseCommandSucc("layout v_scroll", LayoutCmdArgs(rawArgs: [], toggleBetween: [.v_scroll]))
        testParseCommandSucc("layout scroll", LayoutCmdArgs(rawArgs: [], toggleBetween: [.scroll]))
    }

    func testLayoutScrollKeepsOrientation() async throws {
        let root = Workspace.get(byName: name).rootTilingContainer
        root.changeOrientation(.v)
        _ = TestWindow.new(id: 1, parent: root).focusWindow()
        XCTAssertEqual(root.layout, .tiles)
        XCTAssertEqual(root.orientation, .v)

        let result = try await LayoutCommand(args: LayoutCmdArgs(rawArgs: [], toggleBetween: [.scroll]))
            .run(.defaultEnv, .emptyStdin)

        assertEquals(result.exitCode, 0)
        XCTAssertEqual(root.layout, .scroll)
        XCTAssertEqual(root.orientation, .v)
    }

    func testLayoutVerticalInScrollIsSupported() async throws {
        let root = Workspace.get(byName: name).rootTilingContainer
        _ = TestWindow.new(id: 1, parent: root).focusWindow()
        root.layout = .scroll
        root.changeOrientation(.h)

        let result = try await LayoutCommand(args: LayoutCmdArgs(rawArgs: [], toggleBetween: [.vertical]))
            .run(.defaultEnv, .emptyStdin)

        assertEquals(result.exitCode, 0)
        XCTAssertEqual(root.layout, .scroll)
        XCTAssertEqual(root.orientation, .v)
    }
}
