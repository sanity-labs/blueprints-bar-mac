import SwiftUI

@main
struct BlueprintsBarApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            if appState.isDetached {
                WindowRedirectView()
                    .environment(appState)
            } else {
                ContentView()
                    .environment(appState)
            }
        } label: {
            Label("Blueprints", systemImage: "square.stack.3d.up")
        }
        .menuBarExtraStyle(.window)

        Window("Blueprints", id: "detached") {
            ContentView()
                .environment(appState)
                .onAppear { appState.isDetached = true }
                .onDisappear { appState.isDetached = false }
        }
        .defaultSize(width: 480, height: 560)
    }
}

/// Shown inside the MenuBarExtra when the detached window is open.
/// Immediately refocuses the window; the popover auto-dismisses (transient).
private struct WindowRedirectView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .onAppear {
                openWindow(id: "detached")
            }
    }
}
