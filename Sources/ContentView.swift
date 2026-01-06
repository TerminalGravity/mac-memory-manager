import SwiftUI

// MARK: - Design System

struct DesignSystem {
    // Apple-inspired color palette with Sonoma/Ventura vibes
    static let accentGradient = LinearGradient(
        colors: [Color(hex: "007AFF"), Color(hex: "5856D6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let criticalGradient = LinearGradient(
        colors: [Color(hex: "FF3B30"), Color(hex: "FF6B6B")],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let warningGradient = LinearGradient(
        colors: [Color(hex: "FF9500"), Color(hex: "FFCC00")],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let successGradient = LinearGradient(
        colors: [Color(hex: "34C759"), Color(hex: "30D158")],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Premium gauge gradients
    static func gaugeGradient(for percent: Int) -> AngularGradient {
        if percent > 85 {
            return AngularGradient(
                colors: [Color(hex: "FF3B30").opacity(0.7), Color(hex: "FF6B6B"), Color(hex: "FF3B30")],
                center: .center,
                startAngle: .degrees(-90),
                endAngle: .degrees(270)
            )
        }
        if percent > 70 {
            return AngularGradient(
                colors: [Color(hex: "FF9500").opacity(0.7), Color(hex: "FFCC00"), Color(hex: "FF9500")],
                center: .center,
                startAngle: .degrees(-90),
                endAngle: .degrees(270)
            )
        }
        if percent > 50 {
            return AngularGradient(
                colors: [Color(hex: "FFD60A").opacity(0.7), Color(hex: "FFEE58"), Color(hex: "FFD60A")],
                center: .center,
                startAngle: .degrees(-90),
                endAngle: .degrees(270)
            )
        }
        return AngularGradient(
            colors: [Color(hex: "30D158").opacity(0.7), Color(hex: "4ADE80"), Color(hex: "30D158")],
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    // Memory type colors (Activity Monitor inspired)
    static let appMemoryColor = Color(hex: "FFD60A")      // Yellow - App Memory
    static let wiredColor = Color(hex: "FF9F0A")          // Orange - Wired
    static let compressedColor = Color(hex: "BF5AF2")     // Purple - Compressed
    static let cachedColor = Color(hex: "64D2FF")         // Cyan - Cached Files
    static let freeColor = Color(hex: "30D158")           // Green - Free

    // Glass/Frosted background
    static let glassBackground = Color(NSColor.windowBackgroundColor).opacity(0.7)
    static let elevatedSurface = Color(NSColor.controlBackgroundColor)

    static func pressureColor(for percent: Int) -> Color {
        if percent > 85 { return Color(hex: "FF3B30") }
        if percent > 70 { return Color(hex: "FF9500") }
        if percent > 50 { return Color(hex: "FFD60A") }
        return Color(hex: "30D158")
    }

    static func pressureGlow(for percent: Int) -> Color {
        pressureColor(for: percent).opacity(0.4)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Visual Effect Background

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Premium Glass Card (Catalina-style)

struct PremiumGlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 16
    var shadowOpacity: Double = 0.08

    @State private var isHovered = false

    init(padding: CGFloat = 20, cornerRadius: CGFloat = 16, shadowOpacity: Double = 0.08, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowOpacity = shadowOpacity
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Base layer with frosted glass effect
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.85))

                    // Inner highlight (top edge glow like macOS windows)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isHovered ? 0.25 : 0.15),
                                    Color.white.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )

                    // Outer subtle border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
                }
            )
            .shadow(color: Color.black.opacity(shadowOpacity), radius: 12, x: 0, y: 6)
            .shadow(color: Color.black.opacity(shadowOpacity * 0.5), radius: 3, x: 0, y: 2)
            .scaleEffect(isHovered ? 1.002 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
            .onHover { isHovered = $0 }
    }
}

// MARK: - Premium Section Header

struct PremiumSectionHeader: View {
    let title: String
    var icon: String? = nil
    var iconColor: Color = .secondary
    var trailing: AnyView? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .tracking(1.2)

            Spacer()

            if let trailing = trailing {
                trailing
            }
        }
    }
}

// MARK: - Animated Status Dot

struct AnimatedStatusDot: View {
    let color: Color
    let isActive: Bool

    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3

    var body: some View {
        ZStack {
            // Outer glow (pulsing)
            Circle()
                .fill(color.opacity(glowOpacity))
                .frame(width: 16, height: 16)
                .scaleEffect(pulseScale)
                .blur(radius: 2)

            // Inner solid dot
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            // Shine highlight
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.4), Color.clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 5
                    )
                )
                .frame(width: 10, height: 10)
        }
        .onAppear {
            if isActive {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulseScale = 1.3
                    glowOpacity = 0.6
                }
            }
        }
    }
}

// MARK: - Premium Divider

struct PremiumDivider: View {
    var opacity: Double = 0.12
    var horizontal: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.primary.opacity(opacity),
                        Color.primary.opacity(opacity),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .padding(.horizontal, horizontal)
    }
}

// MARK: - Premium Skeleton Loading (Shimmer Effect)

struct SkeletonLoader: View {
    var width: CGFloat
    var height: CGFloat = 16
    var cornerRadius: CGFloat = 4

    @State private var shimmerOffset: CGFloat = -1.0

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.primary.opacity(0.06))
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.15),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset * width)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 2.0
                }
            }
    }
}

// MARK: - Premium Loading Indicator

struct PremiumLoadingIndicator: View {
    @State private var rotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Outer pulsing ring
            Circle()
                .stroke(Color(hex: "007AFF").opacity(0.2), lineWidth: 3)
                .frame(width: 48, height: 48)
                .scaleEffect(pulseScale)

            // Inner spinning arc
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    AngularGradient(
                        colors: [Color(hex: "007AFF").opacity(0.1), Color(hex: "007AFF")],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(rotation))

            // Center icon
            Image(systemName: "memorychip")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "007AFF"))
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
        }
    }
}

// MARK: - Premium Empty State

struct PremiumEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?

    @State private var iconBounce: CGFloat = 0
    @State private var iconOpacity: Double = 0.5
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 20) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.08))
                    .frame(width: 80, height: 80)

                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.secondary.opacity(0.15), Color.secondary.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.secondary.opacity(iconOpacity))
                    .offset(y: iconBounce)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    iconBounce = -6
                    iconOpacity = 0.7
                }
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary.opacity(0.85))

                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 10)

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                        Text(actionTitle)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "007AFF"), Color(hex: "5856D6")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .shadow(color: Color(hex: "007AFF").opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(PremiumButtonStyle())
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                showContent = true
            }
        }
    }
}

// MARK: - Premium Button Style (Press Feedback)

struct PremiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Staggered Animation Modifier

struct StaggeredAnimation: ViewModifier {
    let index: Int
    let baseDelay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 15)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(baseDelay + Double(index) * 0.05)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func staggeredAnimation(index: Int, baseDelay: Double = 0) -> some View {
        modifier(StaggeredAnimation(index: index, baseDelay: baseDelay))
    }
}

// MARK: - Window Draggable Area

struct WindowDraggableArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = WindowDragView()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

class WindowDragView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

// MARK: - Content View

struct ContentView: View {
    @ObservedObject var monitor: MemoryMonitor
    @State private var searchText = ""
    @State private var expandedGroups: Set<String> = []
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var viewMode: ViewMode = .grouped
    @State private var hoveredGroup: String? = nil
    @State private var showCleanupConfirm = false
    @State private var isOptimizing = false
    @State private var optimizeResult: CleanupResult? = nil
    @FocusState private var isSearchFocused: Bool

    // Entrance animation states
    @State private var showHeader = false
    @State private var showDashboard = false
    @State private var showRecommendations = false
    @State private var showProcessList = false

    enum ViewMode: String, CaseIterable {
        case grouped = "Grouped"
        case all = "All Processes"
    }

    var filteredGroups: [ProcessGroup] {
        if searchText.isEmpty {
            return monitor.processGroups
        }
        return monitor.processGroups.filter { group in
            group.name.localizedCaseInsensitiveContains(searchText) ||
            group.processes.contains { $0.displayName.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var filteredProcesses: [AppProcess] {
        if searchText.isEmpty {
            return Array(monitor.processes.prefix(100))
        }
        return monitor.processes.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with entrance animation
            headerSection
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                .opacity(showHeader ? 1 : 0)
                .offset(y: showHeader ? 0 : -20)

            // Memory Dashboard with entrance animation
            memoryDashboard
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .opacity(showDashboard ? 1 : 0)
                .offset(y: showDashboard ? 0 : 15)

            // Recommendations (if needed) with entrance animation
            if let stats = monitor.memoryStats, stats.usedPercent > 70 {
                recommendationsSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .opacity(showRecommendations ? 1 : 0)
                    .offset(y: showRecommendations ? 0 : 10)
            }

            PremiumDivider(opacity: 0.08)
                .opacity(showProcessList ? 1 : 0)

            // Process List with entrance animation
            processListSection
                .opacity(showProcessList ? 1 : 0)
                .offset(y: showProcessList ? 0 : 10)
        }
        .frame(minWidth: 800, minHeight: 750)
        .background(VisualEffectBackground())
        .alert("Memory Manager", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .confirmationDialog("Clean Up Memory?", isPresented: $showCleanupConfirm, titleVisibility: .visible) {
            Button("Clean Claude Zombies") {
                let killed = monitor.cleanupClaudeZombies()
                alertMessage = "Cleaned \(killed) Claude processes, saved \(String(format: "%.0f MB", monitor.lastCleanupSaved))"
                showAlert = killed > 0
            }
            Button("Trim Chrome Helpers") {
                let killed = monitor.killChromeHelpers(keepTop: 3)
                alertMessage = "Closed \(killed) Chrome helper processes"
                showAlert = killed > 0
            }
            Button("Cancel", role: .cancel) { }
        }
        // Keyboard shortcuts via NSEvent monitor
        .focusable()
        .focused($isSearchFocused)
        .onAppear {
            // Staggered entrance animations
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showHeader = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                showDashboard = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
                showRecommendations = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.25)) {
                showProcessList = true
            }

            // Keyboard shortcuts
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command) {
                    switch event.charactersIgnoringModifiers {
                    case "r":
                        monitor.refresh()
                        return nil
                    case "k":
                        showCleanupConfirm = true
                        return nil
                    case "f":
                        isSearchFocused = true
                        return nil
                    default:
                        break
                    }
                }
                return event
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 16) {
            // Premium App Icon with gradient (draggable)
            ZStack {
                // Outer glow
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "007AFF").opacity(0.3))
                    .frame(width: 52, height: 52)
                    .blur(radius: 8)

                // Icon background
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "007AFF"), Color(hex: "5856D6"), Color(hex: "AF52DE")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .shadow(color: Color(hex: "5856D6").opacity(0.4), radius: 10, y: 5)

                // Inner highlight
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.4), Color.white.opacity(0.1), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: "memorychip.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, y: 1)
            }
            .overlay(WindowDraggableArea())

            VStack(alignment: .leading, spacing: 5) {
                Text("Memory Manager")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                if let machine = monitor.machineInfo {
                    HStack(spacing: 6) {
                        Image(systemName: "laptopcomputer")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.7))

                        Text(machine.modelName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        Text("·")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary.opacity(0.3))

                        Text(machine.chip)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.9))

                        Text("·")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary.opacity(0.3))

                        Text("\(machine.memoryGB) GB")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                }
            }

            Spacer()

            // Premium Status Indicator
            if let stats = monitor.memoryStats {
                HStack(spacing: 14) {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(stats.pressureLevel)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(DesignSystem.pressureColor(for: stats.usedPercent))

                        Text("Memory Pressure")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.7))
                    }

                    AnimatedStatusDot(
                        color: DesignSystem.pressureColor(for: stats.usedPercent),
                        isActive: stats.usedPercent > 70
                    )
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DesignSystem.pressureColor(for: stats.usedPercent).opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(DesignSystem.pressureColor(for: stats.usedPercent).opacity(0.15), lineWidth: 1)
                        )
                )
            }

            // Keyboard shortcuts hint
            HStack(spacing: 4) {
                KeyboardShortcutHint(key: "⌘R", label: "Refresh")
                KeyboardShortcutHint(key: "⌘K", label: "Cleanup")
                KeyboardShortcutHint(key: "⌘F", label: "Search")
            }
            .opacity(0.5)

            // Premium refresh button
            Button(action: { monitor.refresh() }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.secondary.opacity(0.1), Color.secondary.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 38, height: 38)

                    Circle()
                        .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)
                        .frame(width: 38, height: 38)

                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(monitor.isRefreshing ? 360 : 0))
                        .animation(monitor.isRefreshing ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: monitor.isRefreshing)
                }
            }
            .buttonStyle(.plain)
            .help("Refresh (⌘R)")
        }
    }

    // MARK: - Memory Dashboard

    private var memoryDashboard: some View {
        PremiumGlassCard(padding: 24, cornerRadius: 20) {
            VStack(spacing: 24) {
                HStack(spacing: 28) {
                    // Large Memory Gauge
                    if let stats = monitor.memoryStats {
                        PremiumMemoryGauge(stats: stats)
                            .frame(width: 190, height: 190)

                        // Memory Breakdown Panel
                        VStack(alignment: .leading, spacing: 18) {
                            PremiumSectionHeader(
                                title: "MEMORY COMPOSITION",
                                icon: "chart.pie.fill",
                                iconColor: .secondary.opacity(0.7)
                            )

                            // Activity Monitor-style breakdown
                            ActivityMonitorBreakdown(stats: stats)

                            // Swap indicator
                            if stats.swapUsedMB > 100 {
                                SwapIndicator(swapMB: stats.swapUsedMB)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Quick Stats Cards
                        VStack(spacing: 12) {
                            QuickStatCard(
                                title: "Available",
                                value: formatGB(stats.freeMB + stats.inactiveMB),
                                subtitle: "Can be freed",
                                color: DesignSystem.freeColor,
                                icon: "checkmark.circle.fill"
                            )

                            QuickStatCard(
                                title: "App Memory",
                                value: formatGB(stats.activeMB),
                                subtitle: "In active use",
                                color: DesignSystem.appMemoryColor,
                                icon: "app.fill"
                            )

                            QuickStatCard(
                                title: "Compressed",
                                value: formatGB(stats.compressedMB),
                                subtitle: "Memory compressor",
                                color: DesignSystem.compressedColor,
                                icon: "arrow.down.right.and.arrow.up.left"
                            )
                        }
                        .frame(width: 165)
                    }
                }

                PremiumDivider(opacity: 0.08)

                // Memory History Graph
                if let stats = monitor.memoryStats {
                    MemoryHistoryGraph(
                        history: monitor.memoryHistory,
                        currentPercent: stats.usedPercent
                    )
                }

                // Hero Optimize Memory Button
                if let stats = monitor.memoryStats {
                    HeroOptimizeButton(
                        stats: stats,
                        isOptimizing: isOptimizing,
                        result: optimizeResult,
                        onOptimize: {
                            isOptimizing = true
                            optimizeResult = nil
                            Task {
                                let result = await monitor.smartCleanup()
                                await MainActor.run {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        optimizeResult = result
                                        isOptimizing = false
                                    }
                                    // Clear result after 5 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                        withAnimation { optimizeResult = nil }
                                    }
                                }
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("RECOMMENDATIONS")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(1)
                Spacer()
            }

            HStack(spacing: 12) {
                if monitor.claudeProcessCount > 5 {
                    RecommendationCard(
                        title: "Clean Claude Processes",
                        description: "\(monitor.claudeProcessCount) processes using \(formatMB(monitor.claudeMemoryMB))",
                        icon: "terminal.fill",
                        color: .orange,
                        action: {
                            let killed = monitor.cleanupClaudeZombies()
                            alertMessage = "Cleaned \(killed) Claude processes"
                            showAlert = killed > 0
                        }
                    )
                }

                if monitor.chromeProcessCount > 8 {
                    RecommendationCard(
                        title: "Trim Chrome Helpers",
                        description: "\(monitor.chromeProcessCount) helpers using \(formatMB(monitor.chromeMemoryMB))",
                        icon: "globe",
                        color: .blue,
                        action: {
                            let killed = monitor.killChromeHelpers(keepTop: 5)
                            alertMessage = "Closed \(killed) Chrome helpers"
                            showAlert = killed > 0
                        }
                    )
                }

                if let stats = monitor.memoryStats, stats.swapUsedMB > 2000 {
                    RecommendationCard(
                        title: "High Swap Usage",
                        description: "\(formatGB(stats.swapUsedMB)) using SSD storage",
                        icon: "arrow.triangle.swap",
                        color: .purple,
                        action: nil
                    )
                }

                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.yellow.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Process List Section

    private var processListSection: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))

                    TextField("Search processes...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                )

                Picker("", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)

            // Column Headers
            HStack(spacing: 0) {
                Text("PROCESS")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("MEMORY")
                    .frame(width: 100, alignment: .trailing)
                Text("CPU")
                    .frame(width: 70, alignment: .trailing)
                Text("")
                    .frame(width: 40)
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(Color(NSColor.separatorColor).opacity(0.1))

            // Process List
            ScrollView {
                LazyVStack(spacing: 0) {
                    if monitor.isRefreshing && monitor.processGroups.isEmpty {
                        // Premium loading state with skeleton
                        VStack(spacing: 24) {
                            PremiumLoadingIndicator()

                            Text("Analyzing memory usage...")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)

                            // Skeleton rows
                            VStack(spacing: 8) {
                                ForEach(0..<4, id: \.self) { index in
                                    HStack(spacing: 12) {
                                        SkeletonLoader(width: 24, height: 24, cornerRadius: 6)
                                        SkeletonLoader(width: 120, height: 14)
                                        Spacer()
                                        SkeletonLoader(width: 60, height: 14)
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                                    .staggeredAnimation(index: index, baseDelay: 0.3)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if monitor.processGroups.isEmpty {
                        // Premium empty state
                        PremiumEmptyState(
                            icon: "memorychip",
                            title: "No Processes Loaded",
                            subtitle: "System may be under heavy pressure.\nTry refreshing or use Optimize Memory above.",
                            actionTitle: "Refresh",
                            action: { monitor.refresh() }
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 50)
                    } else if viewMode == .grouped {
                        ForEach(Array(filteredGroups.enumerated()), id: \.element.id) { index, group in
                            PremiumProcessGroupRow(
                                group: group,
                                isExpanded: expandedGroups.contains(group.id),
                                isHovered: hoveredGroup == group.id,
                                onToggle: { toggleGroup(group.id) },
                                onHover: { hoveredGroup = $0 ? group.id : nil },
                                onKillProcess: { pid in monitor.killProcess(pid) },
                                onKillGroup: {
                                    let killed = monitor.killProcessGroup(group, keepTop: 1)
                                    alertMessage = "Killed \(killed) \(group.name) processes"
                                    showAlert = killed > 0
                                }
                            )
                            .staggeredAnimation(index: index, baseDelay: 0.1)
                        }
                    } else {
                        ForEach(Array(filteredProcesses.enumerated()), id: \.element.id) { index, process in
                            PremiumProcessRow(process: process) {
                                monitor.killProcess(process.id)
                            }
                            .staggeredAnimation(index: index, baseDelay: 0.05)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func toggleGroup(_ id: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if expandedGroups.contains(id) {
                expandedGroups.remove(id)
            } else {
                expandedGroups.insert(id)
            }
        }
    }

    private func formatMB(_ mb: Double) -> String {
        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.0f MB", mb)
    }

    private func formatGB(_ mb: Double) -> String {
        return String(format: "%.1f GB", mb / 1024)
    }
}

// MARK: - Premium Memory Gauge

struct PremiumMemoryGauge: View {
    let stats: MemoryStats
    @State private var animatedPercent: Double = 0
    @State private var pulseOpacity: Double = 0.3
    @State private var glowScale: CGFloat = 1.0
    @State private var innerShimmer: Double = 0

    var gaugeColor: Color {
        DesignSystem.pressureColor(for: stats.usedPercent)
    }

    var body: some View {
        ZStack {
            // Outer ambient glow (pulsing when high pressure)
            if stats.usedPercent > 70 {
                Circle()
                    .fill(gaugeColor.opacity(pulseOpacity * 0.3))
                    .blur(radius: 20)
                    .scaleEffect(glowScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                            pulseOpacity = 0.8
                            glowScale = 1.08
                        }
                    }
            }

            // Background ring with inset depth (Activity Monitor style)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.12),
                            Color.black.opacity(0.05),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 20
                )

            // Inner shadow simulation
            Circle()
                .stroke(Color.black.opacity(0.08), lineWidth: 18)
                .blur(radius: 2)
                .offset(x: 1, y: 2)
                .mask(Circle().stroke(lineWidth: 18))

            // Track background
            Circle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 16)

            // Progress ring with premium gradient
            Circle()
                .trim(from: 0, to: animatedPercent / 100)
                .stroke(
                    DesignSystem.gaugeGradient(for: stats.usedPercent),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: gaugeColor.opacity(0.6), radius: 12, x: 0, y: 4)

            // Shimmer highlight on progress
            Circle()
                .trim(from: max(0, animatedPercent / 100 - 0.15), to: animatedPercent / 100)
                .stroke(
                    LinearGradient(
                        colors: [Color.clear, Color.white.opacity(0.5), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .blur(radius: 1)

            // End cap glow
            if animatedPercent > 5 {
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 8, height: 8)
                    .shadow(color: gaugeColor, radius: 6)
                    .offset(y: -73)
                    .rotationEffect(.degrees(-90 + (animatedPercent / 100 * 360)))
            }

            // Inner glass circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.03),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .padding(26)

            // Inner content
            VStack(spacing: 0) {
                // Percentage display
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(stats.usedPercent)")
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [gaugeColor, gaugeColor.opacity(0.75)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: gaugeColor.opacity(0.3), radius: 8, y: 2)

                    Text("%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(gaugeColor.opacity(0.5))
                        .offset(y: -10)
                }

                // Pressure label with pill background
                Text(stats.pressureLevel.uppercased())
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(gaugeColor)
                    .tracking(2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(gaugeColor.opacity(0.12))
                    )
                    .padding(.top, 2)

                // Memory details
                Text("\(String(format: "%.1f", stats.usedMB / 1024)) / \(String(format: "%.0f", stats.totalMB / 1024)) GB")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.top, 6)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.75)) {
                animatedPercent = stats.usedPercentDouble
            }
        }
        .onChange(of: stats.usedPercent) { newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animatedPercent = Double(newValue)
            }
        }
        .help(stats.pressureDescription)
    }
}

// MARK: - Activity Monitor Breakdown

struct ActivityMonitorBreakdown: View {
    let stats: MemoryStats
    @State private var animatedStats: MemoryStats?
    @State private var animationProgress: Double = 0

    private var displayStats: MemoryStats {
        animatedStats ?? stats
    }

    var body: some View {
        VStack(spacing: 12) {
            // Stacked bar with animation
            GeometryReader { geo in
                HStack(spacing: 1) {
                    Rectangle()
                        .fill(DesignSystem.appMemoryColor)
                        .frame(width: max(0, geo.size.width * (displayStats.activeMB / displayStats.totalMB)))

                    Rectangle()
                        .fill(DesignSystem.wiredColor)
                        .frame(width: max(0, geo.size.width * (displayStats.wiredMB / displayStats.totalMB)))

                    Rectangle()
                        .fill(DesignSystem.compressedColor)
                        .frame(width: max(0, geo.size.width * (displayStats.compressedMB / displayStats.totalMB)))

                    Rectangle()
                        .fill(DesignSystem.cachedColor)
                        .frame(width: max(0, geo.size.width * (displayStats.inactiveMB / displayStats.totalMB)))

                    Rectangle()
                        .fill(DesignSystem.freeColor.opacity(0.5))
                }
                .cornerRadius(4)
            }
            .frame(height: 20)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: stats.usedPercent)

            // Legend
            HStack(spacing: 16) {
                BreakdownLegend(color: DesignSystem.appMemoryColor, label: "App", value: stats.activeMB)
                BreakdownLegend(color: DesignSystem.wiredColor, label: "Wired", value: stats.wiredMB)
                BreakdownLegend(color: DesignSystem.compressedColor, label: "Compressed", value: stats.compressedMB)
                BreakdownLegend(color: DesignSystem.cachedColor, label: "Cached", value: stats.inactiveMB)
            }
        }
    }
}

struct BreakdownLegend: View {
    let color: Color
    let label: String
    let value: Double

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)

                Text(String(format: "%.1fG", value / 1024))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
            }
        }
    }
}

// MARK: - Memory History Graph

struct MemoryHistoryGraph: View {
    let history: [Double]
    let currentPercent: Int

    var pressureColor: Color {
        DesignSystem.pressureColor(for: currentPercent)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MEMORY PRESSURE")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(0.8)

                Spacer()

                Text("Last 5 min")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.7))
            }

            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    // Grid lines
                    VStack(spacing: 0) {
                        ForEach([100, 75, 50, 25], id: \.self) { level in
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 1)
                            Spacer()
                        }
                    }

                    // Gradient fill
                    if history.count > 1 {
                        Path { path in
                            let stepWidth = geo.size.width / CGFloat(max(history.count - 1, 1))
                            path.move(to: CGPoint(x: 0, y: geo.size.height))

                            for (index, value) in history.enumerated() {
                                let x = CGFloat(index) * stepWidth
                                let y = geo.size.height * (1 - value / 100)
                                path.addLine(to: CGPoint(x: x, y: y))
                            }

                            path.addLine(to: CGPoint(x: CGFloat(history.count - 1) * stepWidth, y: geo.size.height))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [pressureColor.opacity(0.3), pressureColor.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        // Line
                        Path { path in
                            let stepWidth = geo.size.width / CGFloat(max(history.count - 1, 1))

                            for (index, value) in history.enumerated() {
                                let x = CGFloat(index) * stepWidth
                                let y = geo.size.height * (1 - value / 100)

                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(
                            LinearGradient(
                                colors: [pressureColor.opacity(0.6), pressureColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: pressureColor.opacity(0.4), radius: 4, y: 2)

                        // Current value dot
                        if let lastValue = history.last {
                            let x = geo.size.width
                            let y = geo.size.height * (1 - lastValue / 100)

                            Circle()
                                .fill(pressureColor)
                                .frame(width: 8, height: 8)
                                .shadow(color: pressureColor.opacity(0.6), radius: 4)
                                .position(x: x, y: y)
                        }
                    } else {
                        Text("Collecting data...")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    // Threshold lines
                    Rectangle()
                        .fill(Color(hex: "FF3B30").opacity(0.3))
                        .frame(height: 1)
                        .offset(y: -geo.size.height * 0.85)

                    Rectangle()
                        .fill(Color(hex: "FF9500").opacity(0.3))
                        .frame(height: 1)
                        .offset(y: -geo.size.height * 0.70)
                }
            }
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.03))
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Swap Indicator

struct SwapIndicator: View {
    let swapMB: Double

    var severity: Color {
        if swapMB > 4000 { return Color(hex: "FF3B30") }
        if swapMB > 2000 { return Color(hex: "FF9500") }
        return Color(hex: "FFD60A")
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.swap")
                .foregroundColor(severity)

            Text("Swap Used:")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            Text(String(format: "%.1f GB", swapMB / 1024))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(severity)

            if swapMB > 2000 {
                Text("• High disk I/O")
                    .font(.system(size: 10))
                    .foregroundColor(severity.opacity(0.8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(severity.opacity(0.1))
        )
    }
}

// MARK: - Quick Stat Card

struct QuickStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String

    @State private var isHovered = false

    private var tooltipText: String {
        switch title {
        case "Available":
            return "Memory that can be freed immediately if apps need it. Includes inactive cached files."
        case "App Memory":
            return "Memory currently used by running applications and their processes."
        case "Compressed":
            return "Memory compressed by macOS to make room for more data without using swap."
        default:
            return subtitle
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Premium icon container
            ZStack {
                // Background glow
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(isHovered ? 0.2 : 0.1))
                    .blur(radius: isHovered ? 4 : 0)

                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(isHovered ? 0.25 : 0.15), color.opacity(isHovered ? 0.15 : 0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)

                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(color.opacity(isHovered ? 0.3 : 0.15), lineWidth: 1)
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
            }
            .frame(width: 32, height: 32)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(isHovered ? color : .primary)

                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .animation(.easeInOut(duration: 0.15), value: isHovered)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(isHovered ? 0.9 : 0.6))

                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isHovered ? 0.15 : 0.08),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(isHovered ? 0.08 : 0.04), radius: isHovered ? 8 : 4, y: isHovered ? 4 : 2)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { isHovered = $0 }
        .help(tooltipText)
    }
}

// MARK: - Recommendation Card

struct RecommendationCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: (() -> Void)?

    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 12) {
                // Premium icon with gradient background
                ZStack {
                    // Icon glow
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(isHovered ? 0.25 : 0.15))
                        .blur(radius: isHovered ? 4 : 0)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.2), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)

                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            LinearGradient(
                                colors: [color.opacity(0.4), color.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(color)
                        .scaleEffect(isHovered ? 1.1 : 1.0)
                }
                .frame(width: 36, height: 36)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(color.opacity(isHovered ? 1 : 0.5))
                        .offset(x: isHovered ? 2 : 0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
                }
            }
            .padding(14)
            .background(
                ZStack {
                    // Base
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(isHovered ? 0.9 : 0.7))

                    // Top edge highlight
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isHovered ? 0.2 : 0.1),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )

                    // Colored accent on left edge
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: 3)
                            .opacity(isHovered ? 1 : 0.5)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            )
            .shadow(color: color.opacity(isHovered ? 0.15 : 0.05), radius: isHovered ? 12 : 6, y: isHovered ? 6 : 3)
            .scaleEffect(isPressed ? 0.97 : (isHovered ? 1.01 : 1.0))
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .disabled(action == nil)
    }
}

// MARK: - Premium Process Group Row

struct PremiumProcessGroupRow: View {
    let group: ProcessGroup
    let isExpanded: Bool
    let isHovered: Bool
    let onToggle: () -> Void
    let onHover: (Bool) -> Void
    let onKillProcess: (Int32) -> Void
    let onKillGroup: () -> Void

    @State private var killButtonHovered = false

    var groupColor: Color {
        switch group.name {
        case "Claude": return .orange
        case "Chrome": return Color(hex: "4285F4")
        case "Safari": return Color(hex: "007AFF")
        case "Xcode": return Color(hex: "147EFB")
        case "Docker": return Color(hex: "2496ED")
        case "VS Code", "Cursor": return Color(hex: "007ACC")
        case "Electron": return Color(hex: "47848F")
        case "Finder": return Color(hex: "4DB6F3")
        case "Terminal": return Color(hex: "2D3436")
        default: return .secondary
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Group Header
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    // Premium expand indicator with rotation
                    ZStack {
                        Circle()
                            .fill(isExpanded ? groupColor.opacity(0.12) : Color.clear)
                            .frame(width: 20, height: 20)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(isExpanded ? groupColor : .secondary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                    .frame(width: 20)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)

                    // Premium app icon with glow
                    ZStack {
                        // Glow on hover
                        if isHovered {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(groupColor.opacity(0.2))
                                .frame(width: 28, height: 28)
                                .blur(radius: 4)
                        }

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [groupColor.opacity(0.2), groupColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 26, height: 26)

                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(groupColor.opacity(isHovered ? 0.4 : 0.2), lineWidth: 1)
                            .frame(width: 26, height: 26)

                        Image(systemName: group.icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(groupColor)
                    }
                    .scaleEffect(isHovered ? 1.05 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)

                    // Name with highlight on hover
                    Text(group.name)
                        .font(.system(size: 13, weight: isHovered ? .semibold : .medium, design: .rounded))
                        .foregroundColor(isHovered ? groupColor : .primary)
                        .animation(.easeInOut(duration: 0.15), value: isHovered)

                    // Process count badge
                    Text("\(group.processCount)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(isHovered ? .white : .secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(isHovered ? groupColor : Color.secondary.opacity(0.12))
                        )
                        .animation(.easeInOut(duration: 0.15), value: isHovered)

                    Spacer()

                    // Memory with gradient when high
                    Text(formatMemory(group.totalMemoryMB))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(
                            group.totalMemoryMB > 2000
                                ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "FF3B30"), Color(hex: "FF6B6B")], startPoint: .leading, endPoint: .trailing))
                                : group.totalMemoryMB > 1000
                                    ? AnyShapeStyle(Color(hex: "FF9500"))
                                    : AnyShapeStyle(Color.primary)
                        )
                        .frame(width: 80, alignment: .trailing)

                    // CPU with visual indicator
                    if group.totalCPU > 1 {
                        HStack(spacing: 4) {
                            // Mini CPU bar
                            RoundedRectangle(cornerRadius: 1)
                                .fill(cpuColor(group.totalCPU))
                                .frame(width: min(20, CGFloat(group.totalCPU) / 5), height: 4)

                            Text(String(format: "%.1f%%", group.totalCPU))
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(cpuColor(group.totalCPU))
                        }
                        .frame(width: 60, alignment: .trailing)
                    } else {
                        Text("—")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.3))
                            .frame(width: 60, alignment: .trailing)
                    }

                    // Premium kill button
                    if group.processCount > 1 {
                        Button(action: onKillGroup) {
                            ZStack {
                                Circle()
                                    .fill(killButtonHovered ? Color.red.opacity(0.15) : Color.clear)
                                    .frame(width: 26, height: 26)

                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(killButtonHovered ? .red : .red.opacity(0.4))
                                    .scaleEffect(killButtonHovered ? 1.1 : 1.0)
                            }
                        }
                        .buttonStyle(.plain)
                        .onHover { killButtonHovered = $0 }
                        .help("Kill all except main process")
                        .frame(width: 28)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: killButtonHovered)
                    } else {
                        Spacer().frame(width: 28)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered || isExpanded ? groupColor.opacity(0.04) : Color.clear)
                        .padding(.horizontal, 12)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { onHover($0) }

            // Expanded content with staggered animation
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(group.processes.enumerated()), id: \.element.id) { index, process in
                        PremiumProcessRow(process: process) {
                            onKillProcess(process.id)
                        }
                        .padding(.leading, 56)
                        .staggeredAnimation(index: index, baseDelay: 0)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(groupColor.opacity(0.02))
                        .padding(.horizontal, 16)
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }

            PremiumDivider(opacity: 0.06, horizontal: isExpanded ? 24 : 60)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
    }

    private func cpuColor(_ cpu: Double) -> Color {
        if cpu > 100 { return Color(hex: "FF3B30") }
        if cpu > 50 { return Color(hex: "FF9500") }
        return .secondary
    }

    private func formatMemory(_ mb: Double) -> String {
        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.0f MB", mb)
    }
}

// MARK: - Premium Process Row

struct PremiumProcessRow: View {
    let process: AppProcess
    let onKill: () -> Void

    @State private var isHovered = false
    @State private var killHovered = false
    @State private var showDetails = false

    var memoryColor: Color {
        if process.memoryMB > 500 { return Color(hex: "FF3B30") }
        if process.memoryMB > 200 { return Color(hex: "FF9500") }
        if process.memoryMB > 100 { return Color(hex: "FFD60A") }
        return Color(hex: "30D158").opacity(0.8)
    }

    var body: some View {
        HStack(spacing: 10) {
            // Process name with ellipsis
            HStack(spacing: 6) {
                // Subtle indicator dot
                Circle()
                    .fill(memoryColor.opacity(isHovered ? 0.8 : 0.4))
                    .frame(width: 5, height: 5)

                Text(process.displayName)
                    .font(.system(size: 12, weight: isHovered ? .medium : .regular, design: .rounded))
                    .foregroundColor(isHovered ? .primary : .primary.opacity(0.9))
                    .lineLimit(1)
            }

            // PID badge with hover effect
            Text("PID \(process.id)")
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundColor(isHovered ? .secondary : .secondary.opacity(0.5))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.secondary.opacity(isHovered ? 0.12 : 0.06))
                )
                .scaleEffect(isHovered ? 1.02 : 1.0)

            Spacer()

            // Premium memory bar with glow
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.08))
                    .frame(width: 44, height: 5)

                // Progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [memoryColor.opacity(0.7), memoryColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: min(44, max(4, 44 * process.memoryMB / 1000)), height: 5)
                    .shadow(color: memoryColor.opacity(isHovered ? 0.5 : 0.2), radius: isHovered ? 3 : 1)
            }

            // Memory value with animation
            Text(formatMemory(process.memoryMB))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(
                    process.memoryMB > 500
                        ? AnyShapeStyle(LinearGradient(colors: [memoryColor, memoryColor.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(memoryColor)
                )
                .frame(width: 65, alignment: .trailing)

            // CPU with visual feedback
            HStack(spacing: 3) {
                if process.cpu > 0.5 {
                    // Mini CPU activity indicator
                    if process.cpu > 20 {
                        CPUActivityIndicator(cpu: process.cpu)
                    }

                    Text(String(format: "%.1f%%", process.cpu))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(cpuColor(process.cpu))
                } else {
                    Text("—")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.2))
                }
            }
            .frame(width: 50, alignment: .trailing)

            // Premium kill button
            Button(action: onKill) {
                ZStack {
                    Circle()
                        .fill(killHovered ? Color.red.opacity(0.12) : Color.clear)
                        .frame(width: 22, height: 22)

                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(killHovered ? .red : .red.opacity(isHovered ? 0.5 : 0.2))
                        .scaleEffect(killHovered ? 1.15 : 1.0)
                }
            }
            .buttonStyle(.plain)
            .frame(width: 24)
            .opacity(isHovered ? 1 : 0.4)
            .onHover { killHovered = $0 }
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: killHovered)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? memoryColor.opacity(0.04) : Color.clear)
                .padding(.horizontal, 12)
        )
        .scaleEffect(isHovered ? 1.003 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isHovered)
        .onHover { isHovered = $0 }
    }

    private func cpuColor(_ cpu: Double) -> Color {
        if cpu > 80 { return Color(hex: "FF3B30") }
        if cpu > 50 { return Color(hex: "FF9500") }
        if cpu > 20 { return Color(hex: "FFD60A") }
        return .secondary
    }

    private func formatMemory(_ mb: Double) -> String {
        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.0f MB", mb)
    }
}

// MARK: - CPU Activity Indicator

struct CPUActivityIndicator: View {
    let cpu: Double

    @State private var pulse = false

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(barColor(for: i))
                    .frame(width: 2, height: barHeight(for: i))
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.1),
                        value: pulse
                    )
            }
        }
        .frame(width: 10, height: 10)
        .onAppear { pulse = true }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = pulse ? 8 : 4
        let variation = CGFloat(index) * 2
        return max(3, min(10, baseHeight - variation + CGFloat.random(in: -1...1)))
    }

    private func barColor(for index: Int) -> Color {
        if cpu > 80 { return Color(hex: "FF3B30") }
        if cpu > 50 { return Color(hex: "FF9500") }
        return Color(hex: "FFD60A")
    }
}

// MARK: - Keyboard Shortcut Hint

struct KeyboardShortcutHint: View {
    let key: String
    let label: String

    var body: some View {
        HStack(spacing: 3) {
            Text(key)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.1))
                )

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary.opacity(0.7))
        }
    }
}

// MARK: - Hero Optimize Button

struct HeroOptimizeButton: View {
    let stats: MemoryStats
    let isOptimizing: Bool
    let result: CleanupResult?
    let onOptimize: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    @State private var showSuccessCheck = false

    private var shouldShow: Bool {
        // Show when memory is above 50% or there's a result to display
        stats.usedPercent > 50 || result != nil
    }

    private var buttonColor: Color {
        if result != nil { return Color(hex: "30D158") }
        if stats.usedPercent > 85 { return Color(hex: "FF3B30") }
        if stats.usedPercent > 70 { return Color(hex: "FF9500") }
        return Color(hex: "007AFF")
    }

    private var buttonGradient: LinearGradient {
        if result != nil {
            return LinearGradient(
                colors: [Color(hex: "30D158"), Color(hex: "34C759")],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        if stats.usedPercent > 85 {
            return LinearGradient(
                colors: [Color(hex: "FF3B30"), Color(hex: "FF6B6B")],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        if stats.usedPercent > 70 {
            return LinearGradient(
                colors: [Color(hex: "FF9500"), Color(hex: "FFCC00")],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        return LinearGradient(
            colors: [Color(hex: "007AFF"), Color(hex: "5856D6")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        if shouldShow {
            Button(action: {
                if !isOptimizing && result == nil {
                    onOptimize()
                }
            }) {
                HStack(spacing: 16) {
                    // Icon with animation
                    ZStack {
                        if isOptimizing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else if result != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .scaleEffect(showSuccessCheck ? 1.0 : 0.5)
                                .opacity(showSuccessCheck ? 1.0 : 0.0)
                        } else {
                            Image(systemName: "bolt.circle.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 28, height: 28)

                    // Text content
                    VStack(alignment: .leading, spacing: 2) {
                        if isOptimizing {
                            Text("Optimizing Memory...")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        } else if let result = result {
                            Text(result.killedCount > 0 ? "Freed \(String(format: "%.0f MB", result.freedMB))" : "Memory Optimized")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            Text(result.killedCount > 0 ? "Cleaned \(result.killedCount) processes" : "No cleanup needed")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        } else {
                            Text("Optimize Memory")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            Text(stats.usedPercent > 85 ? "Critical • Free up space now" :
                                 stats.usedPercent > 70 ? "High usage • Recommended" :
                                 "Clean idle processes")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }

                    Spacer()

                    // Right indicator
                    if !isOptimizing && result == nil {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    ZStack {
                        // Glow effect for high memory
                        if stats.usedPercent > 70 && !isOptimizing && result == nil {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(buttonColor.opacity(glowOpacity))
                                .blur(radius: 12)
                                .scaleEffect(pulseScale)
                        }

                        // Main background
                        RoundedRectangle(cornerRadius: 12)
                            .fill(buttonGradient)
                            .shadow(color: buttonColor.opacity(0.4), radius: 8, y: 4)
                    }
                )
            }
            .buttonStyle(.plain)
            .scaleEffect(isOptimizing ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOptimizing)
            .onAppear {
                if stats.usedPercent > 70 {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        pulseScale = 1.05
                        glowOpacity = 0.5
                    }
                }
            }
            .onChange(of: result != nil) { hasResult in
                if hasResult {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        showSuccessCheck = true
                    }
                } else {
                    showSuccessCheck = false
                }
            }
            .transition(.asymmetric(
                insertion: .scale(scale: 0.95).combined(with: .opacity),
                removal: .scale(scale: 0.95).combined(with: .opacity)
            ))
        }
    }
}

// MARK: - Mini Sparkline

struct MiniSparkline: View {
    let data: [Double]
    let color: Color
    let height: CGFloat

    var body: some View {
        GeometryReader { geo in
            if data.count > 1 {
                Path { path in
                    let stepWidth = geo.size.width / CGFloat(max(data.count - 1, 1))
                    let minVal = data.min() ?? 0
                    let maxVal = data.max() ?? 100
                    let range = maxVal - minVal > 0 ? maxVal - minVal : 1

                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * stepWidth
                        let y = geo.size.height * (1 - (value - minVal) / range)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(height: height)
    }
}
