import SwiftUI

@main
struct bkeyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 900, height: 680)
        .windowResizability(.contentSize)
    }
}
