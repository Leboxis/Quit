import SwiftUI

struct EpisodeView: View {
    var existingID: UUID? = nil
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draftID = UUID()
    @State private var emotion: Emotion?
    @State private var context: Context?
    @State private var trigger: Trigger?
    @State private var date = Date()
    @State private var interruption = ""
    @State private var nextAction = ""
    @State private var returnedToPlan = false
    @State private var keepPlan = false
    @State private var saved = false
    @State private var hydrated = false
    @State private var step = 0
    @State private var showDiscard = false
    @State private var saveError: String?
    private enum InputField: Hashable { case interruption, action }
    @FocusState private var focusedField: InputField?
    @State private var generatedAction: String?

    private var suggestion: EpisodeSuggestion? {
        guard let emotion, let context, let trigger else { return nil }
        return EpisodeSuggestion(emotion: emotion, context: context, trigger: trigger)
    }
    private var condition: String { interruption.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var action: String { nextAction.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var linkedPlan: IfThenPlan? {
        guard let id = store.data.episodes.first(where: { $0.id == existingID })?.planID else { return nil }
        return store.data.plans.first { $0.id == id }
    }
    private var canKeepPlan: Bool {
        !condition.isEmpty && condition.count <= 500 && !action.isEmpty &&
        (linkedPlan != nil || store.data.plans.count < 100 || store.data.plans.contains { $0.condition == condition && $0.action == action })
    }
    private var latestEpisodeDate: Date {
        if returnedToPlan, let recovery = store.data.episodes.first(where: { $0.id == existingID })?.recoveredAt {
            return min(recovery, Date())
        }
        return Date()
    }
    private var canContinue: Bool { step == 0 ? emotion != nil && context != nil : trigger != nil }

    var body: some View {
        NavigationStack {
            ScreenContent {
                if saved { completion }
                else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Environ 60 secondes · à ton rythme").font(.footnote).foregroundStyle(QuitTheme.secondary)
                        ProgressView(value: Double(step + 1), total: 3)
                            .accessibilityLabel("Étape \(step + 1) sur 3")
                        Group {
                            if step == 0 { contextStep }
                            else if step == 1 { sequenceStep }
                            else { planStep }
                        }.id(step)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !saved {
                    QuitBottomBar {
                        if let saveError { Text(saveError).font(.footnote).foregroundStyle(QuitTheme.secondary).accessibilityIdentifier("episode.error") }
                        if step > 0 { Button("Retour") { focusedField = nil; step -= 1 }.frame(minHeight: 44) }
                        QuitPrimaryButton(title: step == 2 ? "Enregistrer" : "Continuer", symbol: step == 2 ? "checkmark" : "arrow.right") {
                            focusedField = nil
                            if step == 2 { save() }
                            else {
                                if step == 1 && (nextAction.isEmpty || nextAction == generatedAction) {
                                    nextAction = suggestion?.action ?? ""
                                    generatedAction = nextAction
                                }
                                step += 1
                            }
                        }
                        .disabled(!canContinue)
                        .accessibilityIdentifier(step == 2 ? "episode.save" : "episode.next")
                    }
                }
            }
            .navigationTitle("Comprendre un épisode").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) {
                Button("Fermer") { if saved { dismiss() } else { showDiscard = true } }
            } }
            .interactiveDismissDisabled(!saved)
            .confirmationDialog("Quitter sans enregistrer l’analyse ?", isPresented: $showDiscard, titleVisibility: .visible) {
                Button("Quitter sans enregistrer", role: .destructive) { dismiss() }
                Button("Continuer l’analyse", role: .cancel) { }
            }
            .onAppear { hydrate() }
            .onChange(of: canKeepPlan) { _, allowed in if !allowed { keepPlan = false } }
        }
    }

    private var contextStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("1 · Juste avant").font(.title2.weight(.semibold))
            Text("Un écart ne remet pas tes apprentissages à zéro. Repère simplement le contexte.").foregroundStyle(QuitTheme.secondary)
            QuitCard {
                DatePicker("Quand ?", selection: $date, in: ...latestEpisodeDate, displayedComponents: [.date, .hourAndMinute])
                    .accessibilityIdentifier("episode.date")
                Picker("Où étais-tu ?", selection: $context) {
                    Text("Choisir").tag(nil as Context?)
                    ForEach(Context.allCases) { Text($0.title).tag(Optional($0)) }
                }.pickerStyle(.menu).accessibilityIdentifier("episode.context")
                Picker("Ton émotion", selection: $emotion) {
                    Text("Choisir").tag(nil as Emotion?)
                    ForEach(Emotion.allCases) { Text($0.title).tag(Optional($0)) }
                }.pickerStyle(.menu).accessibilityIdentifier("episode.emotion")
            }
        }
    }

    private var sequenceStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("2 · Repérer le début").font(.title2.weight(.semibold))
            QuitCard {
                Picker("Le déclencheur", selection: $trigger) {
                    Text("Choisir").tag(nil as Trigger?)
                    ForEach(Trigger.allCases) { Text($0.title).tag(Optional($0)) }
                }.pickerStyle(.menu).accessibilityIdentifier("episode.trigger")
                Text("À quel moment pourrais-tu interrompre la séquence ?").font(.headline)
                TextField("Ex. je prends mon téléphone au lit", text: $interruption, axis: .vertical)
                    .lineLimit(2...5).focused($focusedField, equals: .interruption).accessibilityIdentifier("episode.interruption")
                    .onChange(of: interruption) { _, value in interruption = String(value.prefix(2000)) }
                if let suggestion {
                    Button("Utiliser : \(suggestion.condition)") { interruption = suggestion.condition }
                        .frame(minHeight: 44).accessibilityIdentifier("episode.suggestion")
                }
                Text("Repère le premier petit geste, pas une faute. Tu peux laisser ce champ vide.")
                    .font(.footnote).foregroundStyle(QuitTheme.secondary)
            }
        }
    }

    private var planStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("3 · Choisir la suite").font(.title2.weight(.semibold))
            Text("Une proposition à adapter, pas une obligation.").foregroundStyle(QuitTheme.secondary)
            QuitCard(tinted: true) {
                Text("Si…").font(.headline)
                TextField("Le moment où agir", text: $interruption, axis: .vertical)
                    .lineLimit(1...5).focused($focusedField, equals: .interruption).accessibilityIdentifier("episode.condition")
                    .onChange(of: interruption) { _, value in interruption = String(value.prefix(2000)) }
                Text("Alors…").font(.headline)
                TextField("Mon prochain geste", text: $nextAction, axis: .vertical)
                    .lineLimit(2...4).focused($focusedField, equals: .action).accessibilityIdentifier("episode.plan")
                    .onChange(of: nextAction) { _, value in nextAction = String(value.prefix(500)) }
                Toggle(linkedPlan == nil ? "Ajouter à mes plans Si → Alors" : "Mettre à jour le plan associé", isOn: $keepPlan)
                    .disabled(!canKeepPlan).accessibilityIdentifier("episode.keepPlan")
                if !canKeepPlan {
                    Text(condition.count > 500 ? "Garde ton analyse complète ici. Pour créer une règle, raccourcis le Si à 500 caractères." : store.data.plans.count >= 100 && linkedPlan == nil ? "Tes 100 plans sont conservés. Tu peux enregistrer l’analyse sans ajouter de règle, ou retirer un plan dans Aide." : "Complète les deux phrases pour ajouter une règle. L’analyse peut être enregistrée sans règle.")
                        .font(.footnote).foregroundStyle(QuitTheme.secondary)
                }
            }
            Toggle("Je suis revenu à mon plan maintenant", isOn: $returnedToPlan)
                .accessibilityIdentifier("episode.recovered")
        }
    }

    private var completion: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let saveError { Text(saveError).font(.footnote).foregroundStyle(QuitTheme.secondary) }
            Label("Analyse enregistrée", systemImage: "checkmark.circle").font(.title2.weight(.semibold))
            Text("Tes progrès sont conservés. Choisis un petit geste pour continuer.").foregroundStyle(QuitTheme.secondary)
            if !action.isEmpty {
                QuitCard(tinted: true) {
                    Text("Mon prochain geste").font(.headline)
                    Text(action)
                }
            }
            let reco = JourneyCatalog.recommendation(for: store.data)
            NavigationLink { JourneyPathView(path: reco.path) } label: {
                QuietRow(title: "Une leçon utile : \(reco.path.title)", detail: reco.reason, symbol: "book", tone: .reflection)
            }.buttonStyle(.plain).accessibilityIdentifier("episode.lesson")
            NavigationLink("Sources et limites") { EvidenceView() }.font(.footnote).frame(minHeight: 44)
            if store.data.episodes.first(where: { $0.id == draftID })?.recoveredAt == nil {
                QuitPrimaryButton(title: "Reprendre mon plan maintenant", symbol: "arrow.uturn.forward") {
                    if store.resumePlan(after: draftID) { dismiss() }
                    else { captureSaveError() }
                }.accessibilityIdentifier("episode.resume")
            } else { Label("Plan repris", systemImage: "checkmark").foregroundStyle(QuitTheme.secondary) }
            Button("Terminer") { dismiss() }.frame(maxWidth: .infinity, minHeight: 44).accessibilityIdentifier("episode.finish")
        }
    }

    private func hydrate() {
        guard !hydrated else { return }
        hydrated = true
        if let existing = store.data.episodes.first(where: { $0.id == existingID }) {
            draftID = existing.id
            emotion = existing.emotion
            context = existing.context
            trigger = existing.trigger
            date = min(existing.date, Date())
            interruption = existing.interruption
            nextAction = existing.nextAction ?? ""
            returnedToPlan = existing.recoveredAt != nil
        }
    }

    private func save() {
        guard let emotion, let context, let trigger else { return }
        if let existingID, !store.data.episodes.contains(where: { $0.id == existingID }) {
            saveError = "Cet épisode n’est plus disponible. Ferme l’analyse et retourne au journal."
            return
        }
        saveError = nil
        var episode = Episode(date: date, emotion: emotion, context: context, trigger: trigger)
        episode.id = draftID
        episode.interruption = interruption
        episode.nextAction = nextAction
        saved = store.saveEpisode(episode, keepPlan: keepPlan && canKeepPlan, returnedToPlan: returnedToPlan)
        if !saved { captureSaveError() }
    }

    private func captureSaveError() {
        saveError = store.errorMessage ?? "L’analyse n’a pas été enregistrée. Réessaie : ton brouillon est conservé."
        // The sheet owns this failure, so it remains visible above the presented content.
        store.errorMessage = nil
    }
}
