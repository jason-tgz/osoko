import SwiftUI
import AppKit

public struct OnboardingView: View {
    @ObservedObject private var permissions = PermissionsManager.shared
    @State private var initialScreenRecordingGranted = PermissionsManager.shared.isScreenRecordingGranted
    public var onComplete: () -> Void = {}

    public init(onComplete: @escaping () -> Void = {}) {
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(
                            colors: [.blue, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 58, height: 58)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.top, 10)

                Text("Welcome to Osoko")
                    .font(.title2.bold())

                Text("To capture screenshots silently in the background and respond to hotkeys, Osoko needs standard macOS permissions.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // Permissions Cards List
            VStack(spacing: 12) {
                permissionRow(
                    icon: "display",
                    iconColor: .blue,
                    title: "Screen Recording",
                    description: "Captures snippets, windows, and desktop displays.",
                    isGranted: permissions.isScreenRecordingGranted,
                    extraNote: !permissions.isScreenRecordingGranted ? "Requires restarting Osoko once enabled." : nil,
                    action: { permissions.requestScreenRecording() }
                )

                permissionRow(
                    icon: "keyboard",
                    iconColor: .purple,
                    title: "Accessibility",
                    description: "Enables global hotkeys (⌘⇧S, ⌥⌘S) and bottom-edge slide-out.",
                    isGranted: permissions.isAccessibilityGranted,
                    action: { permissions.requestAccessibility() }
                )

                permissionRow(
                    icon: "folder",
                    iconColor: .teal,
                    title: "Desktop Access",
                    description: "Intercepts native screenshots and saves files to Desktop.",
                    isGranted: permissions.isDesktopAccessGranted,
                    action: { permissions.requestDesktopAccess() }
                )
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 8)

            // Footer / Actions
            VStack(spacing: 10) {
                // If Screen Recording was newly granted while running, recommend restart
                if permissions.isScreenRecordingGranted && !initialScreenRecordingGranted {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Screen Recording enabled! Please restart Osoko for macOS to apply it.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)

                    Button(action: {
                        completeAndRelaunch()
                    }) {
                        Label("Restart Osoko Now", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .padding(.horizontal, 20)
                } else if permissions.allPermissionsGranted {
                    Button(action: {
                        finishOnboarding()
                    }) {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .padding(.horizontal, 20)
                } else {
                    HStack(spacing: 12) {
                        Button(action: {
                            finishOnboarding()
                        }) {
                            Text("Continue Anyway")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button(action: {
                            completeAndRelaunch()
                        }) {
                            Label("Relaunch App", systemImage: "arrow.triangle.2.circlepath")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 18)
        }
        .frame(width: 520, height: 530)
        .onAppear {
            permissions.startPolling()
            initialScreenRecordingGranted = permissions.isScreenRecordingGranted
        }
        .onDisappear {
            permissions.stopPolling()
        }
    }

    private func permissionRow(
        icon: String,
        iconColor: Color,
        title: String,
        description: String,
        isGranted: Bool,
        extraNote: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                    if isGranted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.system(size: 12))
                    }
                }

                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let extraNote {
                    Text(extraNote)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.orange)
                        .padding(.top, 1)
                }
            }

            Spacer()

            if isGranted {
                Text("Granted")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.12), in: Capsule())
            } else {
                Button("Grant Access") {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isGranted ? Color.green.opacity(0.3) : Color.primary.opacity(0.08), lineWidth: 1)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isGranted)
    }

    private func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "osoko.hasCompletedOnboarding")
        onComplete()
    }

    private func completeAndRelaunch() {
        UserDefaults.standard.set(true, forKey: "osoko.hasCompletedOnboarding")
        PermissionsManager.relaunchApp()
    }
}
