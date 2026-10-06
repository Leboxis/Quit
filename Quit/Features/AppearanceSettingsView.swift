import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.quitAccent) private var accent

    var body: some View {
        ScreenContent {
            Text("Ton espace,\nà ton image.").font(.largeTitle.weight(.semibold))
            Text("Des teintes douces et juste le mouvement dont tu as besoin.").foregroundStyle(QuitTheme.secondary)
            QuitCard(tinted: true) {
                Text("APERÇU").font(.caption.weight(.medium)).tracking(1.5).foregroundStyle(accent.color)
                ContourArtwork().frame(height: 70)
                Text("Un geste à la fois.").font(.title2.weight(.medium))
                Text("Ton parcours continue, à ton rythme.").foregroundStyle(QuitTheme.secondary)
                Label("Un espace pour toi", systemImage: "leaf").foregroundStyle(accent.color)
            }
            QuitCard {
                Text("Ton ambiance").font(.headline)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) { themeChoices }
                    VStack(spacing: 12) { themeChoices }
                }
            }
            QuitCard {
                Text("Clair ou sombre").font(.headline)
                Picker("Apparence", selection: preference(\.appearance)) {
                    ForEach(AppAppearance.allCases) { Text($0.title).tag($0) }
                }.modifier(QuitAdaptivePickerStyle()).accessibilityIdentifier("appearance.mode")
                Text("Automatique suit le réglage de ton appareil.").font(.footnote).foregroundStyle(QuitTheme.secondary)
            }
            QuitCard {
                Text("Moins de stimulation").font(.headline)
                Toggle("Réduire les animations", isOn: preference(\.reduceAnimations))
                    .accessibilityIdentifier("comfort.reduceMotion")
                Toggle("Vibrations discrètes", isOn: preference(\.haptics))
                    .accessibilityIdentifier("comfort.haptics")
                Text("L'option Réduire les animations d'iOS reste prioritaire, même si ce bouton est désactivé.")
                    .font(.footnote).foregroundStyle(QuitTheme.secondary)
            }
            QuitCard {
                Text("Ton temps d'observation").font(.headline)
                Picker("Durée du SOS", selection: preference(\.observationDuration)) {
                    ForEach(ObservationDuration.allCases) { Text($0.title).tag($0) }
                }.modifier(QuitAdaptivePickerStyle()).accessibilityIdentifier("comfort.duration")
                Text("90 secondes, 3 ou 5 minutes. Tu peux toujours passer à une action avant la fin.")
                    .font(.footnote).foregroundStyle(QuitTheme.secondary)
            }
            Button("Retrouver les réglages par défaut") { store.update { $0.experience = ExperiencePreferences() } }
                .frame(minHeight: 44).font(.subheadline)
        }
        .navigationTitle("Apparence et confort").navigationBarTitleDisplayMode(.inline)
    }

    private var themeChoices: some View {
        ForEach(AccentTheme.allCases) { theme in
            Button {
                store.update { $0.experience.accent = theme }
            } label: {
                VStack(spacing: 9) {
                    Circle().fill(theme.color).frame(width: 34, height: 34)
                        .overlay { if accent == theme { Image(systemName: "checkmark").font(.headline).foregroundStyle(theme.foreground) } }
                    Text(theme.title).font(.subheadline.weight(.medium)).foregroundStyle(QuitTheme.text)
                }
                .frame(maxWidth: .infinity, minHeight: 82)
                .background(accent == theme ? theme.soft : QuitTheme.background, in: RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain).accessibilityIdentifier("theme.\(theme.rawValue)")
            .accessibilityLabel("Ambiance \(theme.title)")
            .accessibilityAddTraits(accent == theme ? [.isSelected] : [])
        }
    }

    private func preference<Value>(_ keyPath: WritableKeyPath<ExperiencePreferences, Value>) -> Binding<Value> {
        Binding(get: { store.data.experience[keyPath: keyPath] }, set: { value in
            store.update { $0.experience[keyPath: keyPath] = value }
        })
    }
}
