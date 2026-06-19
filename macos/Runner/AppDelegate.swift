import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var appShortcutsChannel: FlutterMethodChannel?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)

    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      appShortcutsChannel = FlutterMethodChannel(
        name: "goalkeeper/app_shortcuts",
        binaryMessenger: controller.engine.binaryMessenger
      )
    }

    wirePreferencesShortcut()
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  @objc private func openPreferences(_ sender: Any?) {
    appShortcutsChannel?.invokeMethod("openSettings", arguments: nil)
  }

  private func wirePreferencesShortcut() {
    guard let appMenu = NSApp.mainMenu?.items.first?.submenu else { return }
    guard let preferencesItem = appMenu.items.first(where: { $0.title == "Preferences…" }) else {
      return
    }

    preferencesItem.target = self
    preferencesItem.action = #selector(openPreferences(_:))
    preferencesItem.isEnabled = true
  }
}
