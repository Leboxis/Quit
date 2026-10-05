import SwiftUI

struct SOSView: View {
    private enum Step: Int { case intensity, pause, observe, choose, reassess, done }
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step: Step = .intensity
    @State private var initial = 5.0
    @State private var final = 5.0
    @State private var emotion: Emotion = .stressed
    @State private var strategy: Strategy = .move
    @State private var outcome: UrgeOutcome = .ongoing
    @State private var deadline = Date()
    @State private var remaining = 90
    @State private var closeConfirmation = false
    @State private var showEpisode = false
    @State private var savedEpisodeID: UUID?
    @State private var sessionDate = Date()

    var body: some View {
        NavigationStack {
            ScreenContent {
                Text("À TON RYTHME").font(.caption.weight(.medium)).tracking(2).foregroundStyle(QuitTheme.secondary)
                switch step {
                case .intensity: intensityStep
                case .pause: pauseStep
                case .observe: observeStep
                case .choose: chooseStep
                case .reassess: reassessStep
                case .done: doneStep
                }
            }
            .navigationTitle("On la traverse").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        if step == .intensity || step == .done { dismiss() }
                        else { closeConfirmation = true }
                    }.accessibilityIdentifier("sos.close")
                }
            }
            .confirmationDialog("Quitter l'exercice ?", isPresented: $closeConfirmation, titleVisibility: .visible) {
                Button("Quitter sans enregistrer", role: .destructive) { dismiss() }
                Button("Continuer", role: .cancel) { }
            } message: { Text("Tu peux revenir quand tu veux. Aucun résultat ne sera déduit de cette session.") }
            .sheet(isPresented: $showEpisode) { EpisodeView(existingID: savedEpisodeID) }
        }
        .task(id: "\(step.rawValue)-\(deadline.timeIntervalSinceReferenceDate)") {
            guard step == .observe else { return }
            while !Task.isCancelled && remaining > 0 {
                remaining = max(0, Int(ceil(deadline.timeIntervalSinceNow)))
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
            }
        }
        .sensoryFeedback(.selection, trigger: step.rawValue)
    }

    private var intensityStep: some View {
        VStack(alignment: .leading, spacing: 26) {
            Text("Une envie n'est\npas un ordre.").font(.largeTitle.weight(.semibold))
            Text("On peut créer un peu d'espace avant le prochain geste.").foregroundStyle(QuitTheme.secondary)
            QuitCard { IntensitySlider(title: "Intensité de l'envie", value: $initial) }
            Text("Juste avant, tu te sentais…").font(.headline)
            EmotionPicker(selection: $emotion)
            QuitPrimaryButton(title: "Créer une pause", symbol: "pause") {
                sessionDate = Date()
                final = initial
                go(.pause)
            }.accessibilityIdentifier("sos.start")
        }
    }

    private var pauseStep: some View {
        VStack(alignment: .leading, spacing: 26) {
            Image(systemName: "door.left.hand.open").font(.system(size: 48, weight: .light)).foregroundStyle(QuitTheme.accent)
            Text("Change le décor.").font(.largeTitle.weight(.semibold))
            QuitCard(tinted: true) {
                Text("Pose le téléphone.").font(.title2.weight(.medium))
                Text("Si tu peux, lève-toi et change de pièce. Tu n'as rien à résoudre pour l'instant.").foregroundStyle(QuitTheme.secondary)
            }
            QuitPrimaryButton(title: "C'est fait") {
                remaining = 90
                deadline = Date().addingTimeInterval(90)
                go(.observe)
            }.accessibilityIdentifier("sos.pause.done")
            Button("Je préfère passer à une action") { go(.choose) }.frame(minHeight: 44)
        }
    }

    private var observeStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Laisse passer\nla vague.").font(.largeTitle.weight(.semibold))
            ContourArtwork(animated: true).frame(height: 160)
            Text(String(format: "%02d:%02d", remaining / 60, remaining % 60))
                .font(.system(size: 50, weight: .medium, design: .rounded)).monospacedDigit()
                .foregroundStyle(QuitTheme.accent)
                .accessibilityLabel("Temps restant").accessibilityValue("\(remaining) secondes")
            Text("Respire naturellement. Remarque les sensations, les pensées et leurs changements. Tu peux choisir de ne pas agir, même si l'envie reste présente.")
                .foregroundStyle(QuitTheme.secondary)
            QuitCard(tinted: true) {
                Text("Prendre de la distance").font(.headline)
                Text("« Je remarque que mon esprit me propose de regarder. »")
            }
            QuitPrimaryButton(title: remaining > 0 ? "Choisir mon prochain geste" : "Continuer", symbol: "arrow.right") { go(.choose) }
                .accessibilityIdentifier("sos.observe.next")
            if remaining == 0 {
                Button("Observer encore 90 secondes") {
                    remaining = 90
                    deadline = Date().addingTimeInterval(90)
                }.frame(minHeight: 44)
            }
            Text("L'envie ne redescend pas toujours en 90 secondes. Ce temps est un repère, pas une promesse.")
                .font(.footnote).foregroundStyle(QuitTheme.secondary)
        }
    }

    private var chooseStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Un prochain\ngeste possible.").font(.largeTitle.weight(.semibold))
            Text("Choisis une action. Tu peux sortir de l'app, puis revenir pour faire le point.").foregroundStyle(QuitTheme.secondary)
            ForEach(store.suggestions(for: emotion)) { item in
                Button { strategy = item } label: {
                    QuitCard(tinted: strategy == item) {
                        HStack {
                            Label(item.title, systemImage: item.symbol).font(.headline)
                            Spacer()
                            if strategy == item { Image(systemName: "checkmark.circle.fill") }
                        }
                        Text(item.instruction).font(.subheadline).foregroundStyle(QuitTheme.secondary)
                    }
                }.buttonStyle(.plain).accessibilityAddTraits(strategy == item ? [.isSelected] : [])
            }
            QuitPrimaryButton(title: "J'ai essayé, faire le point") { go(.reassess) }
                .accessibilityIdentifier("sos.action.done")
        }
    }

    private var reassessStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Et maintenant ?").font(.largeTitle.weight(.semibold))
            QuitCard { IntensitySlider(title: "Envie maintenant", value: $final) }
            VStack(alignment: .leading, spacing: 10) {
                ForEach(UrgeOutcome.allCases) { item in
                    Button { outcome = item } label: {
                        HStack {
                            Text(item.title)
                            Spacer()
                            Image(systemName: outcome == item ? "checkmark.circle.fill" : "circle")
                        }.padding(16).frame(minHeight: 44)
                            .background(outcome == item ? QuitTheme.accentSoft : QuitTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain).accessibilityAddTraits(outcome == item ? [.isSelected] : [])
                }
            }
            QuitPrimaryButton(title: "Enregistrer mon expérience", symbol: "checkmark") { save() }
                .accessibilityIdentifier("sos.save")
        }
    }

    private var doneStep: some View {
        VStack(alignment: .leading, spacing: 26) {
            Image(systemName: outcome == .passed ? "leaf" : "arrow.uturn.forward").font(.system(size: 46, weight: .light)).foregroundStyle(QuitTheme.accent)
            Text(outcome == .passed ? "Tu as créé\nun espace." : "Ton parcours\ncontinue.").font(.largeTitle.weight(.semibold))
            QuitCard(tinted: true) {
                Text("\(Int(initial)) → \(Int(final))").font(.system(.largeTitle, design: .rounded))
                Text("Intensité avant et après").foregroundStyle(QuitTheme.secondary)
            }
            Text(outcome == .passed ? "Tu viens de traverser une envie sans agir dessus. Garde en tête le geste qui t'a aidé." : "Cette expérience compte aussi. Tu peux essayer un autre geste ou demander du soutien.")
                .foregroundStyle(QuitTheme.secondary)
            if outcome == .acted {
                QuitPrimaryButton(title: "Comprendre cet épisode") { showEpisode = true }
            } else if outcome == .ongoing {
                QuitPrimaryButton(title: "Essayer un autre geste") { dismiss() }
                Text("Le bouton SOS reste disponible dès ton retour.").font(.footnote).foregroundStyle(QuitTheme.secondary)
            }
            Button("Revenir à mon parcours") { dismiss() }.frame(minHeight: 44)
                .accessibilityIdentifier("sos.finish")
        }
    }

    private func go(_ next: Step) {
        if next == .choose { strategy = store.suggestions(for: emotion).first ?? .move }
        if reduceMotion { step = next }
        else { withAnimation(.easeInOut(duration: 0.2)) { step = next } }
    }

    private func save() {
        let session = UrgeSession(date: sessionDate, initial: Int(initial), final: Int(final),
                                  strategy: strategy, outcome: outcome, emotion: emotion)
        let episode = outcome == .acted ? Episode(date: Date(), emotion: emotion, context: .elsewhere, trigger: .other) : nil
        if store.update({
            $0.urges.append(session)
            if let episode { $0.episodes.append(episode) }
        }) {
            savedEpisodeID = episode?.id
            go(.done)
        }
    }
}
