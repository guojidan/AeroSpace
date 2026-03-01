@testable import AppBundle
import Common
import XCTest

@MainActor
final class WorkspaceOverviewCommandTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    func testParse() {
        assertNotNil(parseCommand("workspace-overview --no-gui").cmdOrNil)
        assertNotNil(parseCommand("workspace-overview --monitor focused").cmdOrNil)
        assertNotNil(parseCommand("workspace-overview --no-gui --monitor 1").cmdOrNil)
    }

    func testNoGuiRuntime() async throws {
        let workspaceA = Workspace.get(byName: "ws-overview-a")
        let workspaceB = Workspace.get(byName: "ws-overview-b")
        let workspaceC = Workspace.get(byName: "ws-overview-c")
        assertEquals(workspaceA.focusWorkspace(), true)
        assertEquals(workspaceB.focusWorkspace(), true)
        assertEquals(workspaceC.focusWorkspace(), true)

        switch parseCommand("workspace-overview --no-gui --monitor focused") {
            case .cmd(let command):
                let result = try await command.run(.defaultEnv, .emptyStdin)
                assertEquals(result.exitCode, 0)
                let output = result.stdout.joined(separator: "\n")
                let listedWorkspaceCount = [workspaceA.name, workspaceB.name, workspaceC.name]
                    .filter { output.contains($0) }
                    .count
                assertTrue(listedWorkspaceCount >= 2)
            case .failure(let msg):
                XCTFail(msg)
            case .help:
                XCTFail("Unexpected help output")
        }
    }
}
