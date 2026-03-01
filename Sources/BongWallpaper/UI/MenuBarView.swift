import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bong Wallpaper")
                .font(.headline)

            Toggle("Rotate Daily", isOn: Binding(
                get: { viewModel.rotateDaily },
                set: { viewModel.rotateDaily = $0 }
            ))

            Divider()

            Button("Previous") {
                viewModel.previous()
            }
            .disabled(!viewModel.hasWallpapers)

            Button("Next") {
                viewModel.next()
            }
            .disabled(!viewModel.hasWallpapers)

            Button(viewModel.isDownloading ? "Downloading..." : "Download") {
                viewModel.download()
            }
            .disabled(viewModel.isDownloading)

            Divider()

            Text(viewModel.currentTitle)
                .font(.caption)
                .lineLimit(1)

            Text(viewModel.statusMessage)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 320)
    }
}
