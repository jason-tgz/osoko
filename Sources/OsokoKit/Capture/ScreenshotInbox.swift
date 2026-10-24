import Foundation

public enum ScreenshotInbox {
    private static var domain: CFString { "com.apple.screencapture" as CFString }
    private static let savedKey = "OsokoSavedScreenshotSettings"

    public static func apply(targetDirectory: URL) {
        // Save current user settings if not already backed up
        if UserDefaults.standard.dictionary(forKey: savedKey) == nil {
            var current: [String: Any] = [:]
            if let loc = value("location") { current["location"] = loc }
            if let locScreen = value("location-screenshot") { current["location-screenshot"] = locScreen }
            if let target = value("target") { current["target"] = target }
            if let targetScreen = value("target-screenshot") { current["target-screenshot"] = targetScreen }
            if let thumb = value("show-thumbnail") { current["show-thumbnail"] = thumb }
            UserDefaults.standard.set(current, forKey: savedKey)
        }

        let path = targetDirectory.path as NSString
        let file = "file" as NSString

        set("location", path)
        set("location-screenshot", path)
        set("target", file)
        set("target-screenshot", file)
        set("show-thumbnail", false as NSNumber)
    }

    public static func restore() {
        guard let saved = UserDefaults.standard.dictionary(forKey: savedKey) else { return }
        set("location", saved["location"])
        set("location-screenshot", saved["location-screenshot"])
        set("target", saved["target"])
        set("target-screenshot", saved["target-screenshot"])
        set("show-thumbnail", saved["show-thumbnail"])
        UserDefaults.standard.removeObject(forKey: savedKey)
    }

    private static func value(_ key: String) -> NSObject? {
        CFPreferencesCopyAppValue(key as CFString, domain) as? NSObject
    }

    private static func set(_ key: String, _ value: Any?) {
        CFPreferencesSetAppValue(key as CFString, value as CFPropertyList?, domain)
        CFPreferencesAppSynchronize(domain)
    }
}
