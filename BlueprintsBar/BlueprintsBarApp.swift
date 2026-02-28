import SwiftUI

@main
struct BlueprintsBarApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environment(appState)
        } label: {
            Label("Blueprints", systemImage: "square.stack.3d.up")
        }
        .menuBarExtraStyle(.window)

        Window("Blueprints", id: "detached") {
            ContentView()
                .environment(appState)
        }
        .defaultSize(width: 480, height: 560)
    }
}
