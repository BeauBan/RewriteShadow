import SwiftUI

@main
struct RewriteShadowApp: App {
    var body: some Scene {
        MenuBarExtra("RewriteShadow", systemImage: "square.stack.3d.down.right") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
