import AppKit
import OsokoKit

let application = NSApplication.shared
let delegate = OsokoAppDelegate()
application.delegate = delegate
application.setActivationPolicy(.accessory)
application.run()
