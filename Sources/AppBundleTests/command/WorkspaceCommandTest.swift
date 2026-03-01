@testable import AppBundle
import Common
import XCTest

@MainActor
final class WorkspaceCommandTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    func testParseWorkspaceCommand() {
        testParseCommandFail("workspace my mail", msg: "ERROR: Unknown argument 'mail'")
        testParseCommandFail("workspace 'my mail'", msg: "ERROR: Whitespace characters are forbidden in workspace names")
        assertEquals(parseCommand("workspace").errorOrNil, "ERROR: Argument '(<workspace-name>|next|prev|up|down)' is mandatory")
        testParseCommandSucc("workspace next", WorkspaceCmdArgs(target: .relative(.next)))
        testParseCommandSucc("workspace prev", WorkspaceCmdArgs(target: .relative(.prev)))
        // Compatibility: `down`/`up` should behave like `next`/`prev`.
        testParseCommandSucc("workspace down", WorkspaceCmdArgs(target: .relative(.next)))
        testParseCommandSucc("workspace up", WorkspaceCmdArgs(target: .relative(.prev)))
        testParseCommandSucc("workspace --auto-back-and-forth W", WorkspaceCmdArgs(target: .direct(.parse("W").getOrDie()), autoBackAndForth: true))
        assertEquals(parseCommand("workspace --wrap-around W").errorOrNil, "--wrapAround requires using (next|prev|up|down) argument")
        assertEquals(parseCommand("workspace --auto-back-and-forth next").errorOrNil, "--auto-back-and-forth is incompatible with (next|prev|up|down)")
        testParseCommandSucc("workspace next --wrap-around", WorkspaceCmdArgs(target: .relative(.next), wrapAround: true))
        testParseCommandSucc("workspace prev --wrap-around", WorkspaceCmdArgs(target: .relative(.prev), wrapAround: true))
        testParseCommandSucc("workspace down --wrap-around", WorkspaceCmdArgs(target: .relative(.next), wrapAround: true))
        testParseCommandSucc("workspace up --wrap-around", WorkspaceCmdArgs(target: .relative(.prev), wrapAround: true))
        assertEquals(parseCommand("workspace --stdin foo").errorOrNil, "--stdin and --no-stdin require using (next|prev|up|down) argument")
        testParseCommandSucc("workspace --stdin next", WorkspaceCmdArgs(target: .relative(.next)).copy(\.explicitStdinFlag, true))
        testParseCommandSucc("workspace --stdin down", WorkspaceCmdArgs(target: .relative(.next)).copy(\.explicitStdinFlag, true))
        testParseCommandSucc("workspace --stdin prev", WorkspaceCmdArgs(target: .relative(.prev)).copy(\.explicitStdinFlag, true))
        testParseCommandSucc("workspace --stdin up", WorkspaceCmdArgs(target: .relative(.prev)).copy(\.explicitStdinFlag, true))
        testParseCommandSucc("workspace --no-stdin next", WorkspaceCmdArgs(target: .relative(.next)).copy(\.explicitStdinFlag, false))
        testParseCommandSucc("workspace --no-stdin down", WorkspaceCmdArgs(target: .relative(.next)).copy(\.explicitStdinFlag, false))
        testParseCommandSucc("workspace --no-stdin prev", WorkspaceCmdArgs(target: .relative(.prev)).copy(\.explicitStdinFlag, false))
        testParseCommandSucc("workspace --no-stdin up", WorkspaceCmdArgs(target: .relative(.prev)).copy(\.explicitStdinFlag, false))
    }
}
