import SwiftUI

struct PlansView: View {
    @Environment(AppStore.self) private var store
    @State private var showNewPlan = false
    var body: some View {
        ScreenContent {
            Text("Prépare un geste concret avant le moment difficile. Quelques plans qui te ressemblent suffisent.")
                .foregroundStyle(QuitTheme.secondary)
            if store.data.plans.isEmpty {
                ContentUnavailableView("Ton premier plan", systemImage: "arrow.triangle.branch", description: Text("Si je prends mon téléphone au lit, alors je le pose dans la cuisine."))
            }
            ForEach(store.data.plans) { plan in
                QuitCard(tinted: true) {
                    Text("SI").font(.caption.weight(.semibold)).tracking(2).foregroundStyle(QuitTheme.secondary)
                    Text(plan.condition).font(.title3.weight(.medium))
                    Text("ALORS").font(.caption.weight(.semibold)).tracking(2).foregroundStyle(QuitTheme.secondary)
                    Text(plan.action)
                    Button("Retirer ce plan", role: .destructive) { store.update { $0.plans.removeAll { $0.id == plan.id } } }
                        .font(.footnote).frame(minHeight: 44)
                }
            }
            QuitPrimaryButton(title: "Créer un plan", symbol: "plus") { showNewPlan = true }
                .disabled(store.data.plans.count >= 100)
            NavigationLink { EnvironmentView() } label: { QuietRow(title: "Protéger mon environnement", detail: "Réglages iOS et gestes volontaires", symbol: "shield") }
                .buttonStyle(.plain)
        }
        .navigationTitle("Si → Alors").navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showNewPlan) { PlanEditorView() }
    }
}

struct PlanEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var condition = ""
    @State private var action = ""
    private var valid: Bool { !condition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var body: some View {
        NavigationStack {
            ScreenContent {
                Text("Un plan simple.\nUn geste faisable.").font(.largeTitle.weight(.semibold))
                QuitCard {
                    Text("Si…").font(.headline)
                    TextField("La situation que je veux préparer", text: $condition, axis: .vertical).lineLimit(2...4)
                        .onChange(of: condition) { _, value in condition = String(value.prefix(500)) }
                    Text("Alors…").font(.headline)
                    TextField("Le geste que je choisis", text: $action, axis: .vertical).lineLimit(2...4)
                        .onChange(of: action) { _, value in action = String(value.prefix(500)) }
                }
                QuitPrimaryButton(title: "Garder ce plan") {
                    if store.update({ $0.plans.append(IfThenPlan(condition: condition.trimmingCharacters(in: .whitespacesAndNewlines), action: action.trimmingCharacters(in: .whitespacesAndNewlines))) }) { dismiss() }
                }.disabled(!valid)
            }.navigationTitle("Nouveau plan").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fermer") { dismiss() } } }
        }
    }
}

struct EnvironmentView: View {
    var body: some View {
        ScreenContent {
            Text("Rendre le prochain choix plus facile.").font(.title2.weight(.medium))
            QuitCard(tinted: true) {
                Label("Une friction volontaire", systemImage: "shield").font(.headline)
                Text("Cette version de Quit ne peut pas bloquer tes apps ou tes sites. Ses plans t'aident à préparer une action. Le blocage Screen Time intégré demande une distribution et des autorisations Apple adaptées.")
            }
            QuitCard {
                Text("Dans Réglages → Temps d'écran").font(.headline)
                Text("Configure un temps d'arrêt pour ta fenêtre sensible, puis des limites pour les apps que tu choisis. Dans les restrictions de contenu web, iOS propose de limiter les sites pour adultes. Les menus peuvent varier selon la version d'iOS.")
            }
            QuitCard {
                Text("Une place pour le téléphone").font(.headline)
                Text("Choisis un endroit hors de la chambre pour le charger. Prépare ce soir un livre, une tisane ou une autre activité qui te plaît.")
            }
            QuitCard {
                Text("Moins de déclencheurs").font(.headline)
                Text("Désabonne-toi des comptes qui déclenchent le scrolling. Désactive les notifications dont tu n'as pas besoin. Garde les personnes et les activités qui te font du bien.")
            }
            Text("Avec LiveContainer, les extensions iOS et certaines fonctions système ne sont pas disponibles. Aucun bouton de Quit ne prétend activer une protection qu'il ne peut pas appliquer.")
                .font(.footnote).foregroundStyle(QuitTheme.secondary)
        }.navigationTitle("Mon environnement").navigationBarTitleDisplayMode(.inline)
    }
}
