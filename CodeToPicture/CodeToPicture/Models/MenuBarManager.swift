import AppKit
import SwiftUI

@Observable
@MainActor
final class MenuBarManager: NSObject {
    var isEnabled: Bool = false

    @ObservationIgnored
    private var statusItem: NSStatusItem?
    @ObservationIgnored
    private var popover: NSPopover?
    @ObservationIgnored
    private var eventMonitor: Any?

    func enable(
        editorVM: EditorViewModel,
        settings: AppSettings,
        themeManager: ThemeManager,
        purchaseManager: PurchaseManager
    ) {
        guard !isEnabled else { return }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "camera.viewfinder",
            accessibilityDescription: "SnapCode"
        )
        item.button?.target = self
        item.button?.action = #selector(togglePopover(_:))
        statusItem = item

        let rootView = MenuBarPopoverView()
            .environment(editorVM)
            .environment(settings)
            .environment(themeManager)
            .environment(purchaseManager)

        let pop = NSPopover()
        pop.contentSize = NSSize(width: 320, height: 480)
        pop.contentViewController = NSHostingController(rootView: rootView)
        pop.behavior = .transient
        popover = pop

        // Cmd+Shift+1 global hotkey
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 18 {
                Task { @MainActor [weak self] in
                    self?.togglePopover(nil)
                }
            }
        }

        isEnabled = true
    }

    func disable() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        popover?.close()
        popover = nil
        isEnabled = false
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
