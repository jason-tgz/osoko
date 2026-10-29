import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject private var settings = OsokoSettings.shared
    @ObservedObject private var stack = ScreenshotStack.shared
    @ObservedObject private var permissions = PermissionsManager.shared

    public init() {}

    public var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            shortcutsTab
                .tabItem {
                    Label("Shortcuts & Permissions", systemImage: "keyboard")
                }

            actionsTab
                .tabItem {
                    Label("Actions & Toolbar", systemImage: "slider.horizontal.3")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 540)
        .padding(20)
        .onAppear {
            permissions.refreshStatus()
        }
    }

    // MARK: - General Tab
    private var generalTab: some View {
        Form {
            Section {
                Toggle("Show icon in menu bar", isOn: $settings.showMenuBarIcon)
                Text("When turned off, Osoko operates completely headless in the background without Dock or Menu Bar clutter.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Appearance")
            }

            Section {
                Toggle("Auto-collapse to side after \(Int(settings.autoCollapseDelay))s", isOn: $settings.autoCollapseEnabled)
                if settings.autoCollapseEnabled {
                    Stepper("Auto-collapse delay: \(Int(settings.autoCollapseDelay)) seconds", value: $settings.autoCollapseDelay, in: 3...60, step: 1)
                }
                Text("Slides the stack off-screen when inactive. Move cursor to the bottom edge of the screen to slide it back out.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                Toggle("Remove from stack after drag & drop into app", isOn: $settings.consumeOnDrop)
                Toggle("Automatically copy new screenshots to clipboard", isOn: $settings.autoCopyToClipboard)
                Toggle("Play camera sound on capture", isOn: $settings.playShutterSound)
                Toggle("Route macOS shortcuts (⌘⇧4, ⌘⇧5) into Osoko", isOn: $settings.interceptSystemScreenshots)

                Stepper("Maximum stack items: \(settings.maxStackItems)", value: $settings.maxStackItems, in: 1...15)
            } header: {
                Text("Stack Behavior")
            }

            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(settings.saveLocationPath)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .font(.system(size: 11, design: .monospaced))
                    }
                    Spacer()
                    Button("Choose...") {
                        selectSaveDirectory()
                    }
                }

                Toggle("Always prompt to rename when saving", isOn: $settings.promptToRenameOnSave)
                Text("When enabled, clicking Save opens a dialog to rename the file before saving. (You can also hold Option or right-click to Save As).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Save & Download")
            }

            Section {
                Toggle("Launch at Login", isOn: $settings.isLaunchAtLogin)
            } header: {
                Text("System")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Shortcuts Tab
    private var shortcutsTab: some View {
        Form {
            Section {
                shortcutRow(title: "macOS Selection (Intercepted)", keys: "⌘ ⇧ 4")
                shortcutRow(title: "macOS Capture Utility (Intercepted)", keys: "⌘ ⇧ 5")
                shortcutRow(title: "Window Snip", keys: "⌥ ⌘ S")
            } header: {
                Text("Keyboard Shortcuts")
            }

            Section {
                permissionStatusRow(
                    title: "Screen Recording",
                    description: "Captures snippets and windows. (Requires app restart)",
                    isGranted: permissions.isScreenRecordingGranted,
                    action: { permissions.requestScreenRecording() }
                )

                permissionStatusRow(
                    title: "Accessibility",
                    description: "Enables global hotkeys (⌥⌘S) and bottom-edge slide-out.",
                    isGranted: permissions.isAccessibilityGranted,
                    action: { permissions.requestAccessibility() }
                )

                permissionStatusRow(
                    title: "Desktop Folder",
                    description: "Intercepts native captures and saves files to Desktop.",
                    isGranted: permissions.isDesktopAccessGranted,
                    action: { permissions.requestDesktopAccess() }
                )

                HStack {
                    Button("Open Setup Wizard...") {
                        OnboardingWindowController.shared.show(force: true)
                    }

                    Spacer()

                    Button(action: {
                        PermissionsManager.relaunchApp()
                    }) {
                        Label("Relaunch Osoko", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                .padding(.top, 4)
            } header: {
                Text("System Permissions")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Actions & Toolbar Tab
    private var actionsTab: some View {
        Form {
            Section {
                Picker("Top-Right Slot 1", selection: $settings.topActionSlot1) {
                    actionOptions
                }
                .pickerStyle(.menu)

                Picker("Top-Right Slot 2", selection: $settings.topActionSlot2) {
                    actionOptions
                }
                .pickerStyle(.menu)
            } header: {
                Text("Card Toolbar — Top Row")
            } footer: {
                Text("The top-left close button is always available. Set a slot to “None (Hidden)” to hide it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Picker("Bottom-Right Slot 1", selection: $settings.bottomActionSlot1) {
                    actionOptions
                }
                .pickerStyle(.menu)

                Picker("Bottom-Right Slot 2", selection: $settings.bottomActionSlot2) {
                    actionOptions
                }
                .pickerStyle(.menu)
            } header: {
                Text("Card Toolbar — Bottom Row")
            } footer: {
                Text("The dimensions badge is always shown on the bottom-left.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Picker("Single Click", selection: $settings.primaryClickAction) {
                    actionOptions
                }
                .pickerStyle(.menu)

                Picker("Double Click", selection: $settings.doubleClickAction) {
                    actionOptions
                }
                .pickerStyle(.menu)
            } header: {
                Text("Click Gestures")
            } footer: {
                Text("These actions run when you click or double-click the body of a screenshot card.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle(
                    "Enable single-key shortcuts when hovering stack (1, 2, T, S, P, L, R, Space, ⌫)",
                    isOn: $settings.enableHoverShortcuts
                )

                Text("1 copies 1x, 2/C copies the original, T extracts text, S saves (⇧/⌥ for Save As), P pins, L opens a detected QR link, R redacts sensitive data, Space opens, and ⌫ deletes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Hover Shortcuts")
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var actionOptions: some View {
        ForEach(CardActionKind.allCases) { action in
            Label(action.displayName, systemImage: action.iconName)
                .tag(action)
        }
    }

    // MARK: - About Tab
    private var aboutTab: some View {
        VStack(spacing: 16) {
            Spacer()

            OsokoAppIcon()
                .frame(width: 72, height: 72)

            VStack(spacing: 4) {
                Text("osoko")
                    .font(.system(size: 28, weight: .semibold))
                    .tracking(-1)
                Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Development")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Standalone lightweight macOS screenshot shelf and assistant.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Divider().frame(width: 280)

            HStack(spacing: 12) {
                Button("Snip Screenshot Now") {
                    ScreenshotCaptureService.shared.captureInteractive()
                }

                if !stack.items.isEmpty {
                    Button("Clear Stack (\(stack.items.count))") {
                        stack.clearAll()
                    }
                }
            }

            Spacer()

            Button(role: .destructive) {
                NSApp.terminate(nil)
            } label: {
                Text("Quit Osoko")
                    .frame(maxWidth: 160)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding(.bottom, 8)
        }
    }

    private func shortcutRow(title: String, keys: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(keys)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
        }
    }

    private func permissionStatusRow(title: String, description: String, isGranted: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(isGranted ? .green : .yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isGranted {
                Text("Granted")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.1), in: Capsule())
            } else {
                Button("Grant Access") {
                    action()
                }
                .controlSize(.small)
            }
        }
    }

    private func selectSaveDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Select"
        if panel.runModal() == .OK, let url = panel.url {
            settings.saveLocationPath = url.path
        }
    }
}
