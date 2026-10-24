import AppKit

@MainActor
public enum SoundPlayer {
    public static func playShutter() {
        guard OsokoSettings.shared.playShutterSound else { return }
        // Attempt system Screen Capture sound, falling back to Tink if unavailable
        if let sound = NSSound(named: "Screen Capture") {
            sound.play()
        } else if let sound = NSSound(named: "Tink") {
            sound.play()
        }
    }
}
