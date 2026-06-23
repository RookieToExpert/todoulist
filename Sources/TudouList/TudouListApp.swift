import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        activateFrontmostWindow()
        DispatchQueue.main.async { [weak self] in
            self?.activateFrontmostWindow()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.activateFrontmostWindow()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.activateFrontmostWindow()
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        activateFrontmostWindow()
    }

    private func activateFrontmostWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        let candidateWindow = NSApp.keyWindow
            ?? NSApp.mainWindow
            ?? NSApp.windows.first(where: { $0.isVisible })
            ?? NSApp.windows.first

        candidateWindow?.makeKeyAndOrderFront(nil)
        candidateWindow?.orderFrontRegardless()
    }
}

@main
struct TudouListApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .commands {
            SidebarCommands()
        }
    }
}
