import SwiftUI

@main
struct QuitApp: App {
    @State private var store: AppStore

    init() {
        #if DEBUG
        // UI tests get their own empty vault, reused when that test relaunches.
        // Release builds always use the person's normal vault.
        if let token = ProcessInfo.processInfo.environment["QUIT_UI_TEST_VAULT"], UUID(uuidString: token) != nil {
            let directory = URL.applicationSupportDirectory.appendingPathComponent("QuitUITests", isDirectory: true)
                .appendingPathComponent(token, isDirectory: true)
            _store = State(initialValue: AppStore(vault: LocalVault(directory: directory)))
        } else {
            _store = State(initialValue: AppStore())
        }
        #else
        _store = State(initialValue: AppStore())
        #endif
    }
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.environment["QUIT_UI_LARGE_TEXT"] == "1" {
                ExperienceContainer().environment(store).dynamicTypeSize(.accessibility5)
            } else {
                ExperienceContainer().environment(store)
            }
            #else
            ExperienceContainer().environment(store)
            #endif
        }
    }
}

private struct ExperienceContainer: View {
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    var body: some View {
        RootView()
            .environment(\.quitAccent, store.data.experience.accent)
            .environment(\.quitHaptics, store.data.experience.haptics)
            .environment(\.quitReduceMotion, systemReduceMotion || store.data.experience.reduceAnimations)
            .preferredColorScheme(store.data.experience.appearance.colorScheme)
            .tint(store.data.experience.accent.color)
    }
}
