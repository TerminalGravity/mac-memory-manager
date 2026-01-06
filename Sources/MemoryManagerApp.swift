import SwiftUI
import AppKit

@main
struct MemoryManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("Memory Manager", id: "main") {
            ContentView(monitor: appDelegate.memoryMonitor)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 800)
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    let memoryMonitor = MemoryMonitor()
    private var updateTimer: Timer?
    private var statusView: StatusItemView?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupPopover()
        startUpdating()
    }

    private func setupStatusItem() {
        // Use fixed length for our custom view
        statusItem = NSStatusBar.system.statusItem(withLength: 52)

        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self

            // Create custom status view with ring indicator
            let view = StatusItemView(frame: NSRect(x: 0, y: 0, width: 52, height: 22))
            view.monitor = memoryMonitor
            button.addSubview(view)
            view.frame = button.bounds
            view.autoresizingMask = [.width, .height]
            statusView = view
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 520)
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self

        let menuBarView = MenuBarView(monitor: memoryMonitor)
        popover.contentViewController = NSHostingController(rootView: menuBarView)
    }

    private func startUpdating() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.statusView?.needsDisplay = true
            }
        }
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            // Update content before showing
            let menuBarView = MenuBarView(monitor: memoryMonitor)
            popover.contentViewController = NSHostingController(rootView: menuBarView)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    func popoverDidClose(_ notification: Notification) {}
}

// MARK: - Custom Status Item View with Ring Indicator

class StatusItemView: NSView {
    weak var monitor: MemoryMonitor?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let percent = monitor?.memoryStats?.usedPercentDouble ?? 0
        let usedPercent = percent

        // Color based on pressure
        let color: NSColor
        if usedPercent > 85 {
            color = NSColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0) // Red
        } else if usedPercent > 70 {
            color = NSColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0) // Orange
        } else if usedPercent > 50 {
            color = NSColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1.0) // Green
        } else {
            color = NSColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1.0) // Green
        }

        // === Ring Indicator ===
        let ringCenter = CGPoint(x: 12, y: bounds.midY)
        let ringRadius: CGFloat = 7
        let lineWidth: CGFloat = 2.5

        // Background ring
        let bgPath = NSBezierPath()
        bgPath.appendArc(
            withCenter: ringCenter,
            radius: ringRadius,
            startAngle: 0,
            endAngle: 360
        )
        NSColor.gray.withAlphaComponent(0.25).setStroke()
        bgPath.lineWidth = lineWidth
        bgPath.stroke()

        // Progress ring (starts from top, goes clockwise)
        let progress = min(usedPercent / 100.0, 1.0)
        let startAngle: CGFloat = 90 // Top
        let endAngle: CGFloat = 90 - (progress * 360)

        let progressPath = NSBezierPath()
        progressPath.appendArc(
            withCenter: ringCenter,
            radius: ringRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )
        progressPath.lineWidth = lineWidth
        progressPath.lineCapStyle = .round
        color.setStroke()
        progressPath.stroke()

        // === Percentage Text ===
        let percentInt = Int(usedPercent)
        let text = "\(percentInt)%"
        let font = NSFont.monospacedSystemFont(ofSize: 11, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]

        let textSize = (text as NSString).size(withAttributes: attributes)
        let textRect = CGRect(
            x: 24,
            y: (bounds.height - textSize.height) / 2 + 1,
            width: textSize.width,
            height: textSize.height
        )

        (text as NSString).draw(in: textRect, withAttributes: attributes)
    }

    override var allowsVibrancy: Bool { true }
}
