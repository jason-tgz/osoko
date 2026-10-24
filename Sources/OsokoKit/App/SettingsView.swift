import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject private var settings = OsokoSettings.shared
    @ObservedObject private var stack = ScreenshotStack.shared
    @State private var isAccessibilityTrusted = ScreenshotCaptureService.isAccessibilityTrusted()

    public init() {}

    public var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            shortcutsTab
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 480, height: 440)
        .padding(20)
        .onAppear {
            isAccessibilityTrusted = ScreenshotCaptureService.isAccessibilityTrusted()
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
            } header: {
                Text("Save Location")
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
                shortcutRow(title: "Interactive Snip", keys: "⌘ ⇧ S")
                shortcutRow(title: "Window Snip", keys: "⌥ ⌘ S")
                shortcutRow(title: "macOS Selection (Intercepted)", keys: "⌘ ⇧ 4")
                shortcutRow(title: "macOS Capture Utility (Intercepted)", keys: "⌘ ⇧ 5")
            } header: {
                Text("Keyboard Shortcuts")
            }

            Section {
                HStack {
                    Image(systemName: isAccessibilityTrusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(isAccessibilityTrusted ? .green : .yellow)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isAccessibilityTrusted ? "Accessibility Granted" : "Accessibility Permission Needed")
                            .font(.system(size: 13, weight: .medium))
                        Text(isAccessibilityTrusted
                             ? "Global shortcut (⌘⇧S) is active system-wide."
                             : "Required for global hotkeys (⌘⇧S, ⌥⌘S). Standard ⌘⇧4 works without permissions.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if !isAccessibilityTrusted {
                        Button("Grant Access") {
                            ScreenshotCaptureService.requestAccessibility()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                isAccessibilityTrusted = ScreenshotCaptureService.isAccessibilityTrusted()
                            }
                        }
                    }
                }
            } header: {
                Text("Permissions")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - About Tab
    private var aboutTab: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            VStack(spacing: 4) {
                Text("Osoko")
                    .font(.title2.bold())
                Text("Version 1.0.0")
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
