import SwiftUI
import SwiftData

@main
struct bkeyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 1100, height: 700)
        .windowResizability(.contentMinSize)
        .modelContainer(PersistenceManager.shared)
    }
}
