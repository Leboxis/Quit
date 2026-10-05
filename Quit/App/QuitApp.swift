import SwiftUI

@main
struct QuitApp: App {
    @State private var store = AppStore()
    var body: some Scene {
        WindowGroup {
            RootView().environment(store).tint(QuitTheme.accent)
        }
    }
}
