import Foundation
import Combine
import ServiceManagement

@MainActor
public final class OsokoSettings: ObservableObject {
    public static let shared = OsokoSettings()

    private enum Keys {
        static let showMenuBarIcon = "osoko.showMenuBarIcon"
        static let consumeOnDrop = "osoko.consumeOnDrop"
        static let autoCopyToClipboard = "osoko.autoCopyToClipboard"
        static let playShutterSound = "osoko.playShutterSound"
        static let interceptSystemScreenshots = "osoko.interceptSystemScreenshots"
        static let maxStackItems = "osoko.maxStackItems"
        static let saveLocation = "osoko.saveLocation"
        static let autoCollapseEnabled = "osoko.autoCollapseEnabled"
        static let autoCollapseDelay = "osoko.autoCollapseDelay"
        static let promptToRenameOnSave = "osoko.promptToRenameOnSave"
    }

    @Published public var promptToRenameOnSave: Bool {
        didSet { UserDefaults.standard.set(promptToRenameOnSave, forKey: Keys.promptToRenameOnSave) }
    }

    @Published public var showMenuBarIcon: Bool {
        didSet {
            UserDefaults.standard.set(showMenuBarIcon, forKey: Keys.showMenuBarIcon)
            onMenuBarSettingChanged?(showMenuBarIcon)
        }
    }

    @Published public var autoCollapseEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoCollapseEnabled, forKey: Keys.autoCollapseEnabled)
            if !autoCollapseEnabled {
                StackCollapseState.shared.expand()
            } else {
                StackCollapseState.shared.resetCollapseTimer()
            }
        }
    }

    @Published public var autoCollapseDelay: Double {
        didSet {
            UserDefaults.standard.set(autoCollapseDelay, forKey: Keys.autoCollapseDelay)
            StackCollapseState.shared.resetCollapseTimer()
        }
    }

    @Published public var consumeOnDrop: Bool {
        didSet { UserDefaults.standard.set(consumeOnDrop, forKey: Keys.consumeOnDrop) }
    }

    @Published public var autoCopyToClipboard: Bool {
        didSet { UserDefaults.standard.set(autoCopyToClipboard, forKey: Keys.autoCopyToClipboard) }
    }

    @Published public var playShutterSound: Bool {
        didSet { UserDefaults.standard.set(playShutterSound, forKey: Keys.playShutterSound) }
    }

    @Published public var interceptSystemScreenshots: Bool {
        didSet {
            UserDefaults.standard.set(interceptSystemScreenshots, forKey: Keys.interceptSystemScreenshots)
            onInterceptSettingChanged?(interceptSystemScreenshots)
        }
    }

    @Published public var maxStackItems: Int {
        didSet { UserDefaults.standard.set(maxStackItems, forKey: Keys.maxStackItems) }
    }

    @Published public var saveLocationPath: String {
        didSet { UserDefaults.standard.set(saveLocationPath, forKey: Keys.saveLocation) }
    }

    @Published public var isLaunchAtLogin: Bool {
        didSet {
            updateLaunchAtLogin(isLaunchAtLogin)
        }
    }

    public var onMenuBarSettingChanged: ((Bool) -> Void)?
    public var onInterceptSettingChanged: ((Bool) -> Void)?

    public init() {
        let defaults = UserDefaults.standard
        self.showMenuBarIcon = defaults.object(forKey: Keys.showMenuBarIcon) as? Bool ?? false
        self.consumeOnDrop = defaults.object(forKey: Keys.consumeOnDrop) as? Bool ?? true
        self.autoCopyToClipboard = defaults.object(forKey: Keys.autoCopyToClipboard) as? Bool ?? false
        self.playShutterSound = defaults.object(forKey: Keys.playShutterSound) as? Bool ?? true
        self.interceptSystemScreenshots = defaults.object(forKey: Keys.interceptSystemScreenshots) as? Bool ?? true
        self.maxStackItems = defaults.object(forKey: Keys.maxStackItems) as? Int ?? 5
        self.autoCollapseEnabled = defaults.object(forKey: Keys.autoCollapseEnabled) as? Bool ?? true
        self.autoCollapseDelay = defaults.object(forKey: Keys.autoCollapseDelay) as? Double ?? 10.0
        self.promptToRenameOnSave = defaults.object(forKey: Keys.promptToRenameOnSave) as? Bool ?? false

        let defaultDesktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0].path
        self.saveLocationPath = defaults.string(forKey: Keys.saveLocation) ?? defaultDesktop

        self.isLaunchAtLogin = SMAppService.mainApp.status == .enabled
    }

    public var saveLocationURL: URL {
        URL(fileURLWithPath: saveLocationPath, isDirectory: true)
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            print("[OsokoSettings] Launch at login update error: \(error)")
        }
    }
}
