import SwiftUI

@main
struct SynonymBarApp: App {
    var body: some Scene {
        MenuBarExtra("同义词", systemImage: "text.bubble") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
