import SwiftUI

struct SOSView: View {
    @Environment(\.quitAccent) private var accent
    private enum Step: Int, Hashable { case intensity, pause, observe, choose, reassess, done }
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.quitReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var step: Step = .intensity
    @State private var initial = 5.0
    @State private var final = 5.0
    @State private var emotion: Emotion = .stressed
    @State private var strategy: Strategy = .move
    @State private var outcome: UrgeOutcome = .ongoing
    @State private var deadline = Date()
    @State private var remaining = 90
    @State private var duration: ObservationDuration = .ninetySeconds
    @State private var closeConfirmation = false
    @State private var showEpisode = false
    @State private var savedEpisodeID: UUID?
    @State private var sessionDate = Date()
    @State private var showPlanEditor = false

    var body: some View {
        NavigationStack {
            ScreenContent {
                HStack {
                    Text("À TON RYTHME").tracking(1.5)
                    Spacer()
                    Text("\(step.rawValue + 1) / 6").monospacedDigit()
                }.font(.caption.weight(.medium)).foregroundStyle(QuitTheme.secondary)
                ProgressView(value: Double(step.rawValue + 1), total: 6).tint(accent.color)
                    .accessibilityLabel("Étape du SOS").accessibilityValue("\(step.rawValue + 1) sur 6")
                switch step {
                case .intensity: intensityStep
                case .pause: pauseStep
                case .observe: observeStep
                case .choose: chooseStep
                case .reassess: reassessStep
                case .done: doneStep
                }
            }
            .id(step).transition(.opacity)
            .safeAreaInset(edge: .bottom) { QuitBottomBar { stepControls } }
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
            .sheet(isPresented: $showPlanEditor) { SOSPlanEditorView() }
        }
        .onAppear { if step == .intensity { duration = store.data.experience.observationDuration } }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active && step == .observe {
                remaining = max(0, Int(ceil(deadline.timeIntervalSinceNow)))
            }
        }
        .task(id: "\(step.rawValue)-\(deadline.timeIntervalSinceReferenceDate)") {
            guard step == .observe else { return }
            while !Task.isCancelled && remaining > 0 {
                remaining = max(0, Int(ceil(deadline.timeIntervalSinceNow)))
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
            }
        }
    }

    private var intensityStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Une envie n'est pas un ordre.").font(.title2.weight(.semibold))
            Text("On peut créer un peu d'espace avant le prochain geste.").foregroundStyle(QuitTheme.secondary)
            QuitCard { IntensitySlider(title: "Intensité de l'envie", value: $initial) }
            VStack(alignment: .leading, spacing: 8) {
                Text("Temps pour observer l'envie").font(.headline)
                Picker("Temps d'observation", selection: $duration) {
                    ForEach(ObservationDuration.allCases) { Text($0.title).tag($0) }
                }.modifier(QuitAdaptivePickerStyle()).accessibilityIdentifier("sos.duration")
                Text("C'est une durée de pause. Tu peux choisir une action avant la fin.")
                    .font(.footnote).foregroundStyle(QuitTheme.secondary)
            }
            Text("Juste avant, tu te sentais…").font(.headline)
            EmotionPicker(selection: $emotion)
        }
    }

    private var pauseStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            QuitSectionTitle(title: "Change le décor.", symbol: "door.left.hand.open")
            QuitCard(tinted: true) {
                Text("Pose le téléphone.").font(.title2.weight(.medium))
                Text("Si tu peux, lève-toi et change de pièce. Tu n'as rien à résoudre pour l'instant.").foregroundStyle(QuitTheme.secondary)
            }
            Button("Je préfère passer à une action") { go(.choose) }.frame(minHeight: 44)
        }
    }

    private var observeStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Laisse passer la vague.").font(.title2.weight(.semibold))
            ObservationDial(remaining: remaining, total: duration.seconds)
            Text("Respire naturellement. Remarque les sensations, les pensées et leurs changements. Tu peux choisir de ne pas agir, même si l'envie reste présente.")
                .foregroundStyle(QuitTheme.secondary)
            QuitCard(tinted: true, tone: .reflection) {
                Text("Prendre de la distance").font(.headline)
                Text("« Je remarque que mon esprit me propose de regarder. »")
            }
            if remaining == 0 {
                Button("Observer encore \(duration.title)") {
                    remaining = duration.seconds
                    deadline = Date().addingTimeInterval(Double(duration.seconds))
                }.frame(minHeight: 44)
            }
            Text("Tu peux passer à une action à tout moment. Ce temps est un repère, pas une promesse de faire disparaître l'envie.")
                .font(.footnote).foregroundStyle(QuitTheme.secondary)
        }
    }

    private var chooseStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Un prochain geste possible.").font(.title2.weight(.semibold))
            Text("Choisis une action. Tu peux sortir de l'app, puis revenir pour faire le point.").foregroundStyle(QuitTheme.secondary)
            if let plan = store.data.sosPlan, !plan.strategies.isEmpty {
                QuitCard(tinted: true, tone: .reflection) {
                    Text("Ton plan SOS · \(plan.duration.title)").font(.headline)
                    Text(plan.strategies.map(\.title).joined(separator: " · "))
                        .font(.subheadline).foregroundStyle(QuitTheme.secondary)
                }
            }
            Button("Personnaliser mon SOS") { showPlanEditor = true }.frame(minHeight: 44)
            ForEach(store.suggestions(for: emotion)) { item in
                QuitCard(tinted: strategy == item) {
                    Button { strategy = item } label: {
                        HStack {
                            Label(item.title, systemImage: item.symbol).font(.headline)
                            Spacer()
                            if strategy == item { Image(systemName: "checkmark.circle.fill") }
                        }
                        Text(item.instruction).font(.subheadline).foregroundStyle(QuitTheme.secondary)
                    }.buttonStyle(.plain).accessibilityAddTraits(strategy == item ? [.isSelected] : [])
                    HStack {
                        if store.data.favoriteStrategies.contains(item) {
                            Image(systemName: "star.fill").foregroundStyle(QuitTheme.amber)
                        }
                        Spacer()
                        Button(store.data.favoriteStrategies.contains(item) ? "Retirer des favoris" : "Ajouter aux favoris") {
                            store.toggleFavorite(item)
                        }.font(.footnote).frame(minHeight: 44)
                    }
                }
            }
        }
    }

    private var reassessStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Et maintenant ?").font(.title2.weight(.semibold))
            QuitCard { IntensitySlider(title: "Envie maintenant", value: $final) }
            VStack(alignment: .leading, spacing: 10) {
                ForEach(UrgeOutcome.allCases) { item in
                    Button { outcome = item } label: {
                        HStack {
                            Text(item.title)
                            Spacer()
                            Image(systemName: outcome == item ? "checkmark.circle.fill" : "circle")
                        }.padding(16).frame(minHeight: 44)
                            .background(outcome == item ? accent.soft : QuitTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain).accessibilityAddTraits(outcome == item ? [.isSelected] : [])
                }
            }
        }
    }

    private var doneStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            QuitSectionTitle(title: outcome == .passed ? "Tu as créé un espace." : "Ton parcours continue.",
                             symbol: outcome == .passed ? "leaf" : "arrow.uturn.forward")
            QuitCard(tinted: true) {
                Text("\(Int(initial)) → \(Int(final))").font(.system(.largeTitle, design: .rounded))
                Text("Intensité avant et après").foregroundStyle(QuitTheme.secondary)
            }
            Text(outcome == .passed ? "Tu viens de traverser une envie sans agir dessus. Garde en tête le geste qui t'a aidé." : "Cette expérience compte aussi. Tu peux essayer un autre geste ou demander du soutien.")
                .foregroundStyle(QuitTheme.secondary)
            if !store.data.usefulStrategies.contains(strategy) {
                Button("Ce geste m'a aidé") { store.markUseful(strategy) }.frame(minHeight: 44)
            } else {
                Label("Geste marqué comme utile", systemImage: "star.fill").font(.footnote).foregroundStyle(QuitTheme.secondary)
            }
            if outcome == .acted {
                QuitPrimaryButton(title: "Comprendre cet épisode") { showEpisode = true }
            } else if outcome == .ongoing {
                QuitPrimaryButton(title: "Essayer un autre geste") { dismiss() }
                Text("Le bouton SOS reste disponible dès ton retour.").font(.footnote).foregroundStyle(QuitTheme.secondary)
            }
        }
    }

    @ViewBuilder private var stepControls: some View {
        switch step {
        case .intensity:
            QuitPrimaryButton(title: "Créer une pause", symbol: "pause") {
                sessionDate = Date(); final = initial; go(.pause)
            }.accessibilityIdentifier("sos.start")
        case .pause:
            QuitPrimaryButton(title: "C'est fait") {
                remaining = duration.seconds
                deadline = Date().addingTimeInterval(Double(duration.seconds))
                go(.observe)
            }.accessibilityIdentifier("sos.pause.done")
        case .observe:
            QuitPrimaryButton(title: remaining > 0 ? "Choisir mon prochain geste" : "Continuer", symbol: "arrow.right") { go(.choose) }
                .accessibilityIdentifier("sos.observe.next")
        case .choose:
            QuitPrimaryButton(title: "J'ai essayé, faire le point") { go(.reassess) }
                .accessibilityIdentifier("sos.action.done")
        case .reassess:
            QuitPrimaryButton(title: "Enregistrer mon expérience", symbol: "checkmark") { save() }
                .accessibilityIdentifier("sos.save")
        case .done:
            QuitPrimaryButton(title: "Revenir à mon parcours") { dismiss() }
                .accessibilityIdentifier("sos.finish")
        }
    }

    private func go(_ next: Step) {
        if next == .choose { strategy = store.suggestions(for: emotion).first ?? .move }
        if reduceMotion { step = next }
        else { withAnimation(.easeInOut(duration: 0.28)) { step = next } }
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

private struct ObservationDial: View {
    let remaining: Int
    let total: Int
    @Environment(\.quitAccent) private var accent
    @Environment(\.quitReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 14) {
                    timeLabel
                    ProgressView(value: Double(max(0, remaining)), total: Double(total)).tint(accent.color)
                }.frame(maxWidth: .infinity, alignment: .leading)
            } else {
                dial.frame(height: 206)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Temps d'observation restant").accessibilityValue("\(remaining) secondes")
        .accessibilityIdentifier("sos.timer")
    }

    private var dial: some View {
        ZStack {
            ContourArtwork(animated: remaining > 0).opacity(0.35)
            Circle().fill(accent.soft).frame(width: 184, height: 184)
            Circle().stroke(accent.color.opacity(0.14), lineWidth: 3).frame(width: 188, height: 188)
            Circle().trim(from: 0, to: min(1, max(0, Double(remaining) / Double(total))))
                .stroke(accent.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90)).frame(width: 188, height: 188)
                .animation(reduceMotion ? nil : .linear(duration: 0.6), value: remaining)
            timeLabel
        }
    }

    private var timeLabel: some View {
        VStack(spacing: 6) {
            Text(String(format: "%02d:%02d", remaining / 60, remaining % 60))
                .font(.system(.largeTitle, design: .rounded, weight: .medium)).monospacedDigit()
            Text("Observe, simplement.").font(.caption).foregroundStyle(QuitTheme.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(accent.color)
    }
}

struct SOSPlanEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var duration: ObservationDuration = .ninetySeconds
    @State private var selected: Set<Strategy> = []
    var body: some View {
        NavigationStack {
            ScreenContent {
                Text("Ton plan SOS sera proposé en premier.").font(.subheadline).foregroundStyle(QuitTheme.secondary)
                Picker("Durée", selection: $duration) {
                    ForEach(ObservationDuration.allCases) { Text($0.title).tag($0) }
                }.modifier(QuitAdaptivePickerStyle())
                ForEach(Strategy.allCases) { item in
                    Button {
                        if selected.contains(item) { selected.remove(item) }
                        else if selected.count < 3 { selected.insert(item) }
                    } label: {
                        HStack {
                            Label(item.title, systemImage: item.symbol)
                            Spacer()
                            if selected.contains(item) { Image(systemName: "checkmark.circle.fill") }
                        }.padding(12).frame(minHeight: 44)
                    }.buttonStyle(.plain)
                }
                QuitPrimaryButton(title: "Garder mon plan SOS") {
                    if store.update({ $0.sosPlan = SOSPersonalPlan(duration: duration, strategies: Array(selected)) }) { dismiss() }
                }.disabled(selected.isEmpty || selected.count > 3)
                if store.data.sosPlan != nil {
                    Button("Retirer mon plan SOS", role: .destructive) {
                        if store.update({ $0.sosPlan = nil }) { dismiss() }
                    }.frame(minHeight: 44)
                }
            }.navigationTitle("Mon plan SOS").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fermer") { dismiss() } } }
                .onAppear {
                    duration = store.data.sosPlan?.duration ?? store.data.experience.observationDuration
                    selected = Set(store.data.sosPlan?.strategies ?? [])
                }
        }
    }
}
