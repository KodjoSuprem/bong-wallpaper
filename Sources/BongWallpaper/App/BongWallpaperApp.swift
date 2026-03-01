import AppKit
import SwiftUI

@main
struct BongWallpaperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = MenuBarViewModel()

    var body: some Scene {
        MenuBarExtra("Bong Wallpaper", systemImage: "photo.on.rectangle") {
            MenuBarView(viewModel: viewModel)
                .onAppear {
                    viewModel.start()
                }
        }
        .menuBarExtraStyle(.menu)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
