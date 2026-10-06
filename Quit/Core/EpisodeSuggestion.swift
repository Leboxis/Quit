import Foundation

/// Local, transparent suggestions, not predictions or an AI diagnosis.
struct EpisodeSuggestion {
    let condition: String
    let action: String

    init(emotion: Emotion, context: Context, trigger: Trigger) {
        switch trigger {
        case .scrolling, .suggestive:
            condition = "je remarque un contenu qui déclenche mon envie"
        case .stress:
            condition = "je sens le stress monter"
        case .boredom:
            condition = "je commence à scroller par ennui"
        case .thought:
            condition = "une pensée me pousse à chercher du contenu"
        case .habit, .other:
            condition = context == .bed ? "je prends mon téléphone au lit" : "je remarque le début de mon automatisme"
        }
        if context == .bed {
            action = "je pose mon téléphone hors de la chambre et je change de pièce"
        } else if emotion == .lonely {
            action = "je propose à une personne de confiance de parler quelques minutes"
        } else if trigger == .scrolling || trigger == .suggestive {
            action = "je ferme le contenu et je pose mon téléphone hors de portée"
        } else {
            action = "je change de pièce et je prends une minute pour observer mon envie"
        }
    }
}
