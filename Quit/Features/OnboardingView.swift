import SwiftUI

struct OnboardingView: View {
    @Environment(AppStore.self) private var store
    @State private var step = 0
    @State private var name = ""
    @State private var intention = ""
    @State private var goal: Goal = .stop
    @State private var sensitiveHour = 23

    var body: some View {
        NavigationStack {
            ScreenContent {
                HStack {
                    Text("QUIT").font(.caption.weight(.semibold)).tracking(3).foregroundStyle(QuitTheme.accent)
                    Spacer()
                    Text("\(step + 1) / 3").font(.caption).foregroundStyle(QuitTheme.secondary)
                }
                if step == 0 { welcome }
                else if step == 1 { intentionStep }
                else { prepareStep }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    QuitPrimaryButton(title: step == 0 ? "Créer mon parcours" : step == 1 ? "Continuer" : "Commencer", symbol: "arrow.right") {
                        if step < 2 { step += 1 }
                        else { finish() }
                    }
                    .accessibilityIdentifier("onboarding.next")
                    if step > 0 {
                        Button("Retour") { step -= 1 }.frame(minHeight: 44).foregroundStyle(QuitTheme.secondary)
                    }
                }.padding(.horizontal, 22).padding(.vertical, 14).background(QuitTheme.background)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 26) {
            Text("Reprends\nla main.").font(.system(.largeTitle, design: .rounded).weight(.semibold))
            ContourArtwork().frame(height: 170)
            Text("Un peu plus de liberté.\nUn geste à la fois.").font(.title2.weight(.medium))
            Text("Observe tes habitudes, traverse les envies et construis un quotidien qui te ressemble.")
                .font(.body).foregroundStyle(QuitTheme.secondary)
            QuitCard(tinted: true) {
                Label("Ton espace, tes choix", systemImage: "lock.shield").font(.headline)
                Text("Aucun compte. Données sur cet appareil. Aucun jugement.").foregroundStyle(QuitTheme.secondary)
            }
            Text("Quit est un soutien personnel, pas un diagnostic ni un traitement médical. La masturbation et la sexualité ne sont pas considérées ici comme des échecs.")
                .font(.footnote).foregroundStyle(QuitTheme.secondary)
        }
    }

    private var intentionStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Qu'est-ce que tu veux retrouver ?").font(.largeTitle.weight(.bold))
            Text("Ton objectif t'appartient. Il pourra évoluer.").foregroundStyle(QuitTheme.secondary)
            Picker("Mon objectif", selection: $goal) {
                ForEach(Goal.allCases) { Text($0.title).tag($0) }
            }.pickerStyle(.segmented)
            TextField("Prénom ou pseudonyme (facultatif)", text: $name)
                .textContentType(.nickname).textFieldStyle(.roundedBorder)
                .onChange(of: name) { _, value in name = String(value.prefix(100)) }
            TextField("Mon intention, en une phrase", text: $intention, axis: .vertical)
                .lineLimit(3...5).textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("onboarding.intention")
                .onChange(of: intention) { _, value in intention = String(value.prefix(2000)) }
            QuitCard {
                Text("Par exemple").font(.headline)
                Text("« Retrouver mes soirées et une sexualité qui me ressemble. »").foregroundStyle(QuitTheme.secondary)
            }
        }
    }

    private var prepareStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Préparons un\npremier geste.").font(.largeTitle.weight(.bold))
            Text("Quel moment aimerais-tu mieux protéger ?").foregroundStyle(QuitTheme.secondary)
            Stepper("À partir de \(sensitiveHour) h", value: $sensitiveHour, in: 0...23)
                .font(.headline).padding(20).background(QuitTheme.surface, in: RoundedRectangle(cornerRadius: 24))
            QuitCard(tinted: true) {
                Text("Si → Alors").font(.headline)
                Text("Si je prends mon téléphone au lit après \(sensitiveHour) h, alors je le pose hors de la chambre.")
            }
            Text("C'est une intention volontaire. Quit ne bloque pas automatiquement tes applications.")
                .font(.footnote).foregroundStyle(QuitTheme.secondary)
            Text("Tu n'as pas besoin d'être parfait pour commencer.").font(.title3.weight(.medium))
        }
    }

    private func finish() {
        store.update {
            $0.profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            $0.profile.intention = intention.trimmingCharacters(in: .whitespacesAndNewlines)
            $0.profile.goal = goal
            $0.profile.sensitiveHour = sensitiveHour
            $0.profile.startedAt = Date()
            $0.profile.onboardingComplete = true
            $0.plans = [IfThenPlan(condition: "Je prends mon téléphone au lit après \(sensitiveHour) h",
                                   action: "Je le pose hors de la chambre")]
        }
    }
}
