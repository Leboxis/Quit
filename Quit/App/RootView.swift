import LocalAuthentication
import SwiftUI

struct RootView: View {
    @Environment(\.quitAccent) private var accent
    @Environment(AppStore.self) private var store
    @Environment(\.scenePhase) private var phase
    @State private var lock = AppLockState()
    @State private var authContext: LAContext?
    @State private var authError: String?

    private var requiresUnlock: Bool { store.data.profile.biometricLock && !lock.unlocked }
    var body: some View {
        ZStack {
            Group {
                if let error = store.loadError {
                    StorageRecoveryView(message: error)
                } else if store.data.profile.onboardingComplete {
                    AppTabs()
                } else {
                    OnboardingView()
                }
            }
            .opacity(requiresUnlock || phase != .active ? 0 : 1)
            .allowsHitTesting(!requiresUnlock && phase == .active)
            .accessibilityHidden(requiresUnlock || phase != .active)

            if requiresUnlock || phase != .active {
                VStack(spacing: 22) {
                    Image(systemName: "leaf").font(.system(size: 44, weight: .light)).foregroundStyle(accent.color)
                    Text("Quit").font(.largeTitle.weight(.semibold))
                    if phase == .active && requiresUnlock {
                        Text("Ton espace personnel").foregroundStyle(QuitTheme.secondary)
                        QuitPrimaryButton(title: lock.authenticating ? "Déverrouillage…" : "Déverrouiller", symbol: "lock.open") {
                            Task { await authenticate() }
                        }.disabled(lock.authenticating).frame(maxWidth: 280)
                        if let authError { Text(authError).font(.footnote).foregroundStyle(QuitTheme.secondary).padding() }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(QuitTheme.background).ignoresSafeArea()
            }
        }
        .foregroundStyle(QuitTheme.text)
        .onChange(of: phase) { _, value in
            lock.sceneChanged(to: value)
            if value == .background {
                authContext?.invalidate()
                authContext = nil
                authError = nil
            }
        }
        .alert("Enregistrement impossible", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
            Button("Compris") { store.errorMessage = nil }
        } message: { Text(store.errorMessage ?? "") }
    }

    private func authenticate() async {
        guard phase == .active, let token = lock.beginAuthentication() else { return }
        authError = nil
        let context = LAContext()
        authContext = context
        do {
            let succeeded = try await context.evaluatePolicy(.deviceOwnerAuthentication,
                                                             localizedReason: "Ouvrir ton espace personnel Quit")
            guard lock.finishAuthentication(token, succeeded: succeeded, phase: phase) else { return }
        } catch {
            guard lock.finishAuthentication(token, succeeded: false, phase: phase) else { return }
            authError = "Déverrouillage indisponible. Réessaie avec Face ID ou le code de l'appareil."
        }
        authContext = nil
    }
}

struct AppTabs: View {
    @Environment(\.quitAccent) private var accent
    @State private var selection = 0
    @State private var showSOS = false
    @State private var showSettings = false

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                tabs.tabViewBottomAccessory { sosButton }
            } else {
                tabs.safeAreaInset(edge: .bottom, spacing: 0) {
                    sosButton.padding(.horizontal, 22).padding(.vertical, 8).background(.regularMaterial)
                }
            }
        }
        .fullScreenCover(isPresented: $showSOS) { SOSView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    private var tabs: some View {
        TabView(selection: $selection) {
            Tab("Aujourd'hui", systemImage: "sun.max", value: 0) {
                tabNavigation { TodayView() }
            }
            Tab("Parcours", systemImage: "leaf", value: 1) {
                tabNavigation { JourneyView() }
            }
            Tab("Comprendre", systemImage: "chart.xyaxis.line", value: 2) {
                tabNavigation { InsightsView() }
            }
            Tab("Aide", systemImage: "heart", value: 3) {
                tabNavigation { HelpView(onSOS: { showSOS = true }) }
            }
        }
    }

    private var sosButton: some View {
        Button {
            showSOS = true
        } label: {
            HStack {
                Image(systemName: "water.waves")
                Text("J'ai une envie").font(.headline)
                Spacer()
                Image(systemName: "arrow.up.right").font(.subheadline)
            }
            .foregroundStyle(accent.color)
            .padding(.horizontal, 20).frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("sos.open")
        .accessibilityHint("Ouvre un exercice pour traverser l'envie")
    }

    private func tabNavigation<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            content()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Réglages", systemImage: "slider.horizontal.3") { showSettings = true }
                            .accessibilityIdentifier("settings.open")
                    }
                }
        }
    }
}
