import AppKit
import Carbon
import SwiftUI

private final class WorkspaceOverviewHostingView: NSHostingView<WorkspaceOverviewView> {
    var onKeyDown: ((NSEvent) -> Bool)?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        if onKeyDown?(event) == true {
            return
        }
        super.keyDown(with: event)
    }
}

public final class WorkspaceOverviewPanel: NSPanelHud {
    @MainActor public static var shared: WorkspaceOverviewPanel = WorkspaceOverviewPanel()

    private var hostingView: WorkspaceOverviewHostingView?

    override public var canBecomeKey: Bool { true }
    override public var canBecomeMain: Bool { true }

    override private init() {
        super.init()
        hasShadow = true
    }

    @MainActor
    func show(model: WorkspaceOverviewModel, monitor: Monitor) {
        let rootView = WorkspaceOverviewView(model: model)
        let hostingView = WorkspaceOverviewHostingView(rootView: rootView)
        hostingView.onKeyDown = { [weak model] event in
            guard let model else { return false }
            return WorkspaceOverviewPanel.handle(event: event, model: model)
        }

        if contentView == nil {
            contentView = NSView(frame: .zero)
        }
        contentView?.subviews.removeAll()
        self.hostingView = hostingView
        contentView?.addSubview(hostingView)
        hostingView.frame = NSRect(origin: .zero, size: model.panelSize)

        let panelFrame = frame(monitor: monitor, panelSize: model.panelSize)
        setFrame(panelFrame, display: true)

        NSApp.setActivationPolicy(.accessory)
        NSApp.activate(ignoringOtherApps: true)
        orderFrontRegardless()
        makeKeyAndOrderFront(nil)
        makeFirstResponder(hostingView)
    }

    @MainActor
    private func frame(monitor: Monitor, panelSize: CGSize) -> NSRect {
        let x = monitor.rect.topLeftX + (monitor.rect.width - panelSize.width) / 2
        let yFromTop = monitor.rect.topLeftY + (monitor.rect.height - panelSize.height) / 2
        let y = mainMonitor.height - yFromTop - panelSize.height
        return NSRect(x: x, y: y, width: panelSize.width, height: panelSize.height)
    }

    @MainActor
    private static func handle(event: NSEvent, model: WorkspaceOverviewModel) -> Bool {
        switch event.keyCode {
            case UInt16(kVK_UpArrow):
                model.moveUp()
                return true
            case UInt16(kVK_DownArrow):
                model.moveDown()
                return true
            case UInt16(kVK_Return), UInt16(kVK_ANSI_KeypadEnter):
                model.submitSelection()
                return true
            case UInt16(kVK_Escape):
                model.close()
                return true
            default:
                return false
        }
    }
}
