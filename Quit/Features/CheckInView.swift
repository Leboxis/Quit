import SwiftUI

struct CheckInView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var emotion: Emotion
    @State private var urge: Double
    @State private var energy: Int
    @State private var stress: Int
    @State private var alignment: Int

    init(existing: DailyCheckIn? = nil) {
        // One-time form seed; save commits the edited value to the parent store.
        _emotion = State(initialValue: existing?.emotion ?? .calm)
        _urge = State(initialValue: Double(existing?.urge ?? 0))
        _energy = State(initialValue: existing?.energy ?? 2)
        _stress = State(initialValue: existing?.stress ?? 2)
        _alignment = State(initialValue: existing?.aligned.map { $0 ? 1 : 2 } ?? 0)
    }

    var body: some View {
        NavigationStack {
            ScreenContent {
                Text("Là, tu te sens plutôt…").font(.headline)
                EmotionPicker(selection: $emotion)
                QuitCard {
                    levelPicker("Énergie", value: $energy, labels: ["Basse", "Moyenne", "Bonne"])
                    levelPicker("Stress", value: $stress, labels: ["Faible", "Modéré", "Élevé"])
                }
                QuitCard { IntensitySlider(title: "Envie maintenant", value: $urge) }
                QuitCard {
                    Text("Ta journée est-elle alignée avec ton objectif ?").font(.headline)
                    Picker("Journée alignée", selection: $alignment) {
                        Text("Pas encore sûr").tag(0)
                        Text("Oui").tag(1)
                        Text("Non").tag(2)
                    }.modifier(QuitAdaptivePickerStyle())
                    Text("Une réponse incertaine reste un jour sans bilan. Tu peux la modifier plus tard.")
                        .font(.footnote).foregroundStyle(QuitTheme.secondary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                QuitBottomBar {
                    QuitPrimaryButton(title: "Enregistrer", symbol: "checkmark") {
                        let item = DailyCheckIn(date: Date(), emotion: emotion, energy: energy, stress: stress,
                                                urge: Int(urge), aligned: alignment == 0 ? nil : alignment == 1)
                        if store.saveCheckIn(item) { dismiss() }
                    }.accessibilityIdentifier("checkin.save")
                }
            }
            .navigationTitle("Comment ça va ?").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fermer") { dismiss() } } }
        }
    }

    private func levelPicker(_ title: String, value: Binding<Int>, labels: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            Picker(title, selection: value) {
                Text(labels[0]).tag(1)
                Text(labels[1]).tag(2)
                Text(labels[2]).tag(3)
            }.modifier(QuitAdaptivePickerStyle())
        }
    }
}
