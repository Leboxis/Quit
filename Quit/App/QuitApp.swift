import SwiftUI

@main
struct QuitApp: App {
    @State private var store = AppStore()
    var body: some Scene {
        WindowGroup {
            ExperienceContainer().environment(store)
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
