import SwiftUI

struct InsightsGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScreenContent {
                QuitCard {
                    QuitSectionTitle(title: "Mes journées", symbol: "calendar")
                    Text("Les graphiques couvrent les 30 derniers jours, ou le temps écoulé depuis ton arrivée si c'est plus court.")
                    Text("Une coche correspond à un objectif respecté. Un cercle indique un écart enregistré ou un objectif non atteint. Un jour sans réponse certaine reste sans bilan : il ne compte pas comme réussi.")
                }
                QuitCard {
                    QuitSectionTitle(title: "Calendrier des check-ins", symbol: "calendar.badge.clock", tone: .reflection)
                    Text("Le calendrier montre si tu as fait ton check-in, indépendamment de la réponse sur ton objectif. Appuie sur une date pour retrouver ton humeur, ton énergie, ton stress et l'intensité de ton envie.")
                }
                QuitCard {
                    QuitSectionTitle(title: "Avant et après", symbol: "water.waves", tone: .reflection)
                    Text("Les losanges et les pointillés montrent l'envie avant une action. Les points et la ligne continue la montrent après, sur une échelle de 0 à 10. Une évolution négative indique une baisse.")
                    Text("Une envie compte comme traversée seulement lorsque tu as indiqué être passé à autre chose. Une session encore en cours ne compte pas comme traversée.")
                }
                QuitCard {
                    QuitSectionTitle(title: "Actions et moments", symbol: "clock", tone: .preparation)
                    Text("Les variations moyennes décrivent tes observations ; elles ne prouvent pas qu'une action a causé la baisse. Peu d'essais donnent peu de recul.")
                    Text("Les émotions et les moments regroupent les envies et les épisodes enregistrés. Un même moment peut donc produire deux signaux. Les nombres de la grille sont des saisies, et le tiret signifie aucune saisie : ce n'est pas une prédiction de risque.")
                }
                QuitCard {
                    QuitSectionTitle(title: "Retour au plan", symbol: "arrow.uturn.forward")
                    Text("La durée moyenne utilise uniquement les épisodes pour lesquels tu as renseigné un retour au plan. Le journal permet de le noter après coup.")
                }
            }
            .navigationTitle("Lire mes graphiques").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Terminé") { dismiss() } } }
        }
    }
}
