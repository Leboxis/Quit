import SwiftUI

struct EpisodeView: View {
    var existingID: UUID? = nil
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var emotion: Emotion = .tired
    @State private var context: Context = .bed
    @State private var trigger: Trigger = .habit
    @State private var date = Date()
    @State private var interruption = ""
    @State private var nextAction = ""
    @State private var returnedToPlan = false
    @State private var saved = false

    var body: some View {
        NavigationStack {
            ScreenContent {
                if saved { completion }
                else { form }
            }
            .navigationTitle("Comprendre un épisode").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fermer") { dismiss() } } }
            .onAppear {
                if let existing = store.data.episodes.first(where: { $0.id == existingID }) {
                    emotion = existing.emotion
                    context = existing.context
                    trigger = existing.trigger
                    date = existing.date
                    interruption = existing.interruption
                    returnedToPlan = existing.recoveredAt != nil
                }
            }
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Ton parcours\ncontinue.").font(.largeTitle.weight(.semibold))
            Text("Un épisode ne supprime pas ce que tu as appris. Regardons ce qui l'a précédé.")
                .foregroundStyle(QuitTheme.secondary)
            DatePicker("Quand ?", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
            Text("Juste avant, tu te sentais…").font(.headline)
            EmotionPicker(selection: $emotion)
            QuitCard {
                Picker("Où ?", selection: $context) { ForEach(Context.allCases) { Text($0.title).tag($0) } }
                Picker("Déclencheur", selection: $trigger) { ForEach(Trigger.allCases) { Text($0.title).tag($0) } }
            }
            QuitCard(tinted: true) {
                Text("Où interrompre la séquence ?").font(.headline)
                TextField("Ex. je prends mon téléphone au lit", text: $interruption, axis: .vertical)
                    .lineLimit(2...4).accessibilityIdentifier("episode.interruption")
                    .onChange(of: interruption) { _, value in interruption = String(value.prefix(500)) }
                TextField("Alors, la prochaine fois je…", text: $nextAction, axis: .vertical)
                    .lineLimit(2...4).accessibilityIdentifier("episode.plan")
                    .onChange(of: nextAction) { _, value in nextAction = String(value.prefix(500)) }
                Text("Ces deux phrases créeront un plan Si → Alors. Elles peuvent rester vides.")
                    .font(.footnote).foregroundStyle(QuitTheme.secondary)
            }
            Toggle("Je suis revenu à mon plan maintenant", isOn: $returnedToPlan)
            QuitPrimaryButton(title: "Enregistrer", symbol: "checkmark") { save() }
                .accessibilityIdentifier("episode.save")
        }
    }

    private var completion: some View {
        VStack(alignment: .leading, spacing: 26) {
            ContourArtwork().frame(height: 150)
            Text("Apprendre.\nReprendre.\nContinuer.").font(.largeTitle.weight(.semibold))
            Text("Tes progrès sont conservés. Un prochain geste suffit pour repartir.").foregroundStyle(QuitTheme.secondary)
            QuitPrimaryButton(title: "Revenir à mon parcours") { dismiss() }
        }
    }

    private func save() {
        let condition = interruption.trimmingCharacters(in: .whitespacesAndNewlines)
        let action = nextAction.trimmingCharacters(in: .whitespacesAndNewlines)
        var episode = store.data.episodes.first(where: { $0.id == existingID }) ?? Episode(date: date, emotion: emotion, context: context, trigger: trigger)
        episode.date = date
        episode.emotion = emotion
        episode.context = context
        episode.trigger = trigger
        episode.interruption = condition
        episode.recoveredAt = returnedToPlan ? episode.recoveredAt ?? Date() : nil
        saved = store.update { data in
            if let index = data.episodes.firstIndex(where: { $0.id == episode.id }) { data.episodes[index] = episode }
            else { data.episodes.append(episode) }
            if !condition.isEmpty && !action.isEmpty { data.plans.append(IfThenPlan(condition: condition, action: action)) }
        }
    }
}
