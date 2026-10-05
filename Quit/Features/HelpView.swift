import MessageUI
import SwiftUI

struct HelpView: View {
    let onSOS: () -> Void
    var body: some View {
        ScreenContent {
            Text("Tu peux être\naccompagné.").font(.title2.weight(.medium))
            QuitCard(tinted: true) {
                Label("Une envie maintenant ?", systemImage: "water.waves").font(.headline)
                Text("Créer une pause, observer, choisir un geste.").foregroundStyle(QuitTheme.secondary)
                QuitPrimaryButton(title: "Ouvrir SOS") { onSOS() }
            }
            NavigationLink { SupportContactView() } label: {
                QuitCard { QuietRow(title: "J'ai besoin de parler", detail: "Une personne que tu choisis", symbol: "bubble.left.and.bubble.right") }
            }.buttonStyle(.plain)
            NavigationLink { PlansView() } label: {
                QuitCard { QuietRow(title: "Mes plans Si → Alors", detail: "Préparer les moments sensibles", symbol: "arrow.triangle.branch") }
            }.buttonStyle(.plain)
            NavigationLink { ProfessionalHelpView() } label: {
                QuitCard { QuietRow(title: "Un soutien professionnel", detail: "Trouver un accompagnement", symbol: "person.crop.circle.badge.checkmark") }
            }.buttonStyle(.plain)
            NavigationLink { EvidenceView() } label: {
                QuitCard { QuietRow(title: "Sources et limites", detail: "Comprendre les outils", symbol: "book") }
            }.buttonStyle(.plain)
        }.navigationTitle("Aide")
    }
}

struct SupportContactView: View {
    @Environment(AppStore.self) private var store
    @State private var name = ""
    @State private var phone = ""
    @State private var saved = false
    @State private var showComposer = false
    private let message = "Salut, je traverse un moment difficile. Tu as 5 minutes pour parler ?"
    var body: some View {
        ScreenContent {
            Text("Pas besoin de tout expliquer.").font(.title2.weight(.medium))
            Text("Choisis une personne de confiance. Quit ne lui transmet aucun suivi ni aucune statistique.").foregroundStyle(QuitTheme.secondary)
            QuitCard {
                TextField("Prénom (facultatif)", text: $name).textContentType(.name)
                    .onChange(of: name) { _, value in name = String(value.prefix(100)); saved = false }
                TextField("Numéro de téléphone (facultatif)", text: $phone).keyboardType(.phonePad)
                    .onChange(of: phone) { _, value in phone = String(value.prefix(100)); saved = false }
                Button(saved ? "Contact conservé" : "Garder ce contact") {
                    saved = store.update { $0.profile.contactName = name; $0.profile.contactPhone = phone }
                }.frame(minHeight: 44)
            }
            QuitCard(tinted: true) {
                Text("Un message possible").font(.headline)
                Text("« \(message) »")
                if MFMessageComposeViewController.canSendText() && !phone.isEmpty {
                    QuitPrimaryButton(title: "Préparer un SMS", symbol: "message") { showComposer = true }
                } else {
                    ShareLink(item: message) { Label("Partager ce message", systemImage: "square.and.arrow.up").frame(minHeight: 44) }
                    Text("La rédaction de SMS peut être indisponible dans LiveContainer. Tu peux copier ou partager le texte dans l'app de ton choix.")
                        .font(.footnote).foregroundStyle(QuitTheme.secondary)
                }
            }
            Text("Tu choisis le destinataire et tu confirmes l'envoi dans l'app de messagerie.")
                .font(.footnote).foregroundStyle(QuitTheme.secondary)
        }
        .navigationTitle("Besoin de parler").navigationBarTitleDisplayMode(.inline)
        .onAppear { name = store.data.profile.contactName; phone = store.data.profile.contactPhone }
        .sheet(isPresented: $showComposer) { MessageComposer(recipient: phone, message: message) }
    }
}

struct MessageComposer: UIViewControllerRepresentable {
    let recipient: String
    let message: String
    @Environment(\.dismiss) private var dismiss
    func makeCoordinator() -> Coordinator { Coordinator(onFinish: { dismiss() }) }
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.recipients = [recipient]
        controller.body = message
        controller.messageComposeDelegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ controller: MFMessageComposeViewController, context: Context) { }
    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onFinish: () -> Void
        init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) { onFinish() }
    }
}

struct ProfessionalHelpView: View {
    var body: some View {
        ScreenContent {
            Text("Une aide adaptée\nà ta situation.").font(.title2.weight(.medium))
            QuitCard(tinted: true) {
                Text("Quand demander du soutien ?").font(.headline)
                Text("Si tu perds régulièrement le contrôle, si cela affecte tes relations, ton travail ou ton bien-être, ou si tu te sens en difficulté, un professionnel peut t'aider à comprendre ce qui se passe.")
            }
            QuitCard {
                Text("En France").font(.headline)
                Text("Les CSAPA proposent un accueil gratuit et confidentiel. Contacte le centre pour vérifier son accompagnement des comportements sexuels compulsifs ou demander une orientation.")
                Link("Trouver une structure d'aide", destination: URL(string: "https://www.drogues-info-service.fr/Adresses-utiles")!).frame(minHeight: 44)
                Link("Comprendre l'accueil en CSAPA", destination: URL(string: "https://www.drogues-info-service.fr/Tout-savoir-sur-les-drogues/Se-faire-aider/L-aide-specialisee-ambulatoire")!).frame(minHeight: 44)
            }
            QuitCard {
                Text("Dans un autre pays").font(.headline)
                Text("Consulte un médecin, un psychologue ou un service local de santé sexuelle. Tu peux dire : « Mon usage de pornographie me semble difficile à contrôler et j'aimerais de l'aide. »")
            }
            Text("Une culpabilité liée à tes valeurs ne suffit pas, à elle seule, à diagnostiquer un trouble. Quit ne pose aucun diagnostic.")
                .font(.footnote).foregroundStyle(QuitTheme.secondary)
        }.navigationTitle("Soutien professionnel").navigationBarTitleDisplayMode(.inline)
    }
}

struct EvidenceView: View {
    var body: some View {
        ScreenContent {
            Text("Des outils,\npas des promesses.").font(.title2.weight(.medium))
            QuitCard {
                Text("ACT et TCC").font(.headline)
                Text("Observer ses habitudes, travailler avec ses pensées et ses valeurs, et préparer les moments difficiles s'inspire d'approches étudiées pour l'usage problématique de pornographie. Les études restent limitées et hétérogènes. Elles ne valident pas cette app ni son programme de six semaines.")
                Link("Essai ACT · Crosby & Twohig, 2016", destination: URL(string: "https://pubmed.ncbi.nlm.nih.gov/27157029/")!).frame(minHeight: 44)
                Link("Revue des traitements, 2023", destination: URL(string: "https://pubmed.ncbi.nlm.nih.gov/37880509/")!).frame(minHeight: 44)
            }
            QuitCard {
                Text("Observer une envie").font(.headline)
                Text("L'observation attentive et l'urge surfing viennent notamment de la prévention des rechutes. Les preuves spécifiques à la pornographie sont plus restreintes. L'exercice est une option de régulation ; il ne promet pas de faire disparaître une envie.")
            }
            QuitCard {
                Text("Un écart n'efface pas l'apprentissage").font(.headline)
                Text("Le journal sert à trouver une interruption possible et un prochain geste. Aucun seuil arbitraire de jours ne garantit une récupération. Les graphiques montrent des associations personnelles, sans diagnostic ni prédiction.")
            }
            QuitCard {
                Text("Sexualité et santé").font(.headline)
                Text("Le trouble du comportement sexuel compulsif implique une perte de contrôle persistante et un retentissement significatif. Un désir sexuel élevé ou un jugement moral ne suffisent pas. L'objectif de Quit porte sur l'usage de pornographie que tu souhaites changer.")
                Link("Description clinique de l'ICD-11 · OMS", destination: URL(string: "https://www.who.int/publications/i/item/9789240077263")!).frame(minHeight: 44)
            }
            Text("Contenus éducatifs originaux. Aucun questionnaire diagnostique ni score clinique soumis à licence n'est reproduit.")
                .font(.footnote).foregroundStyle(QuitTheme.secondary)
        }.navigationTitle("Sources et limites").navigationBarTitleDisplayMode(.inline)
    }
}
