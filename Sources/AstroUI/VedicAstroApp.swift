import SwiftUI
import AstroCore
#if os(macOS)
import AppKit
#endif

// MARK: - Notifications

extension Notification.Name {
    static let saveBeforeQuit = Notification.Name("saveBeforeQuit")
    static let forceQuitAllowed = Notification.Name("forceQuitAllowed")
}

@main
struct VedicAstroApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentMinSize)
    }
}

#if os(macOS)
final class AppDelegate: NSObject, NSApplicationDelegate, @unchecked Sendable {
    var forceQuitAllowed = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            for window in NSApp.windows {
                window.makeKeyAndOrderFront(nil)
                window.becomeKey()
            }
            NSApp.activate(ignoringOtherApps: true)
        }

        NotificationCenter.default.addObserver(
            forName: .forceQuitAllowed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.forceQuitAllowed = true
        }
    }

    /// Closing the last window should quit the app
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if forceQuitAllowed {
            return .terminateNow
        }

        // Ask SwiftUI to show the save prompt
        NotificationCenter.default.post(name: .saveBeforeQuit, object: nil)
        return .terminateCancel
    }
}
#endif
