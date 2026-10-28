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
        static let topActionSlot1 = "osoko.topActionSlot1"
        static let topActionSlot2 = "osoko.topActionSlot2"
        static let bottomActionSlot1 = "osoko.bottomActionSlot1"
        static let bottomActionSlot2 = "osoko.bottomActionSlot2"
        static let primaryClickAction = "osoko.primaryClickAction"
        static let doubleClickAction = "osoko.doubleClickAction"
        static let enableHoverShortcuts = "osoko.enableHoverShortcuts"
    }

    @Published public var promptToRenameOnSave: Bool {
        didSet { UserDefaults.standard.set(promptToRenameOnSave, forKey: Keys.promptToRenameOnSave) }
    }

    // MARK: - Card Action Slots

    @Published public var topActionSlot1: CardActionKind {
        didSet { UserDefaults.standard.set(topActionSlot1.rawValue, forKey: Keys.topActionSlot1) }
    }

    @Published public var topActionSlot2: CardActionKind {
        didSet { UserDefaults.standard.set(topActionSlot2.rawValue, forKey: Keys.topActionSlot2) }
    }

    @Published public var bottomActionSlot1: CardActionKind {
        didSet { UserDefaults.standard.set(bottomActionSlot1.rawValue, forKey: Keys.bottomActionSlot1) }
    }

    @Published public var bottomActionSlot2: CardActionKind {
        didSet { UserDefaults.standard.set(bottomActionSlot2.rawValue, forKey: Keys.bottomActionSlot2) }
    }

    @Published public var primaryClickAction: CardActionKind {
        didSet { UserDefaults.standard.set(primaryClickAction.rawValue, forKey: Keys.primaryClickAction) }
    }

    @Published public var doubleClickAction: CardActionKind {
        didSet { UserDefaults.standard.set(doubleClickAction.rawValue, forKey: Keys.doubleClickAction) }
    }

    @Published public var enableHoverShortcuts: Bool {
        didSet { UserDefaults.standard.set(enableHoverShortcuts, forKey: Keys.enableHoverShortcuts) }
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
        self.topActionSlot1 = Self.loadAction(forKey: Keys.topActionSlot1, default: .saveToFolder)
        self.topActionSlot2 = Self.loadAction(forKey: Keys.topActionSlot2, default: .pin)
        self.bottomActionSlot1 = Self.loadAction(forKey: Keys.bottomActionSlot1, default: .copyDownscaled)
        self.bottomActionSlot2 = Self.loadAction(forKey: Keys.bottomActionSlot2, default: .share)
        self.primaryClickAction = Self.loadAction(forKey: Keys.primaryClickAction, default: .copyOriginal)
        self.doubleClickAction = Self.loadAction(forKey: Keys.doubleClickAction, default: .openInPreview)
        self.enableHoverShortcuts = defaults.object(forKey: Keys.enableHoverShortcuts) as? Bool ?? true

        let defaultDesktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0].path
        self.saveLocationPath = defaults.string(forKey: Keys.saveLocation) ?? defaultDesktop

        self.isLaunchAtLogin = SMAppService.mainApp.status == .enabled
    }

    public var saveLocationURL: URL {
        URL(fileURLWithPath: saveLocationPath, isDirectory: true)
    }

    private static func loadAction(forKey key: String, default defaultValue: CardActionKind) -> CardActionKind {
        guard let rawValue = UserDefaults.standard.string(forKey: key),
              let action = CardActionKind(rawValue: rawValue) else {
            return defaultValue
        }
        return action
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
