import Foundation

enum Goal: String, Codable, CaseIterable, Identifiable {
    case stop, reduce
    var id: Self { self }
    var title: String { self == .stop ? "Arrêter" : "Réduire" }
}

enum Emotion: String, Codable, CaseIterable, Identifiable {
    case calm, stressed, lonely, bored, tired, anxious, excited
    var id: Self { self }
    var title: String {
        switch self {
        case .calm: "Calme"
        case .stressed: "Stressé"
        case .lonely: "Seul"
        case .bored: "Ennuyé"
        case .tired: "Fatigué"
        case .anxious: "Anxieux"
        case .excited: "Excité"
        }
    }
    var symbol: String {
        switch self {
        case .calm: "leaf"
        case .stressed: "bolt"
        case .lonely: "person"
        case .bored: "cloud"
        case .tired: "moon"
        case .anxious: "wind"
        case .excited: "sparkle"
        }
    }
}

enum Context: String, Codable, CaseIterable, Identifiable {
    case bed, bathroom, desk, elsewhere
    var id: Self { self }
    var title: String {
        switch self {
        case .bed: "Au lit"
        case .bathroom: "Salle de bain"
        case .desk: "Au bureau"
        case .elsewhere: "Ailleurs"
        }
    }
}

enum Trigger: String, Codable, CaseIterable, Identifiable {
    case scrolling, thought, stress, boredom, suggestive, habit, other
    var id: Self { self }
    var title: String {
        switch self {
        case .scrolling: "Réseaux sociaux"
        case .thought: "Pensée ou fantasme"
        case .stress: "Stress"
        case .boredom: "Ennui"
        case .suggestive: "Contenu suggestif"
        case .habit: "Habitude"
        case .other: "Autre"
        }
    }
}

enum Strategy: String, Codable, CaseIterable, Identifiable {
    case walk, connect, move, observe
    var id: Self { self }
    var title: String {
        switch self {
        case .walk: "Marcher 10 minutes"
        case .connect: "Parler à quelqu'un"
        case .move: "Changer de pièce"
        case .observe: "Observer l'envie"
        }
    }
    var symbol: String {
        switch self {
        case .walk: "figure.walk"
        case .connect: "bubble.left.and.bubble.right"
        case .move: "door.left.hand.open"
        case .observe: "water.waves"
        }
    }
    var instruction: String {
        switch self {
        case .walk: "Laisse le téléphone. Marche dans un endroit où tu te sens en sécurité, même quelques minutes."
        case .connect: "Choisis une personne de confiance. Tu peux simplement lui demander de parler, sans rien expliquer."
        case .move: "Va dans une autre pièce, si possible un espace partagé. Pose le téléphone hors de portée."
        case .observe: "Observe les sensations et les pensées. Tu n'as pas besoin de les faire disparaître pour choisir ton prochain geste."
        }
    }
}

enum UrgeOutcome: String, Codable, CaseIterable, Identifiable {
    case passed, ongoing, acted
    var id: Self { self }
    var title: String {
        switch self {
        case .passed: "Je suis passé à autre chose"
        case .ongoing: "Je traverse encore l'envie"
        case .acted: "J'ai eu un épisode"
        }
    }
}

struct UserProfile: Codable {
    var startedAt = Date()
    var name = ""
    var intention = ""
    var goal: Goal = .stop
    var sensitiveHour = 23
    var contactName = ""
    var contactPhone = ""
    var biometricLock = false
    var reminderEnabled = false
    var reminderHour = 21
    var reminderMinute = 0
    var onboardingComplete = false
}

struct DailyCheckIn: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var emotion: Emotion
    var energy: Int
    var stress: Int
    var urge: Int
    var aligned: Bool?
}

struct UrgeSession: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var initial: Int
    var final: Int
    var strategy: Strategy
    var outcome: UrgeOutcome
    var emotion: Emotion
}

struct Episode: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var emotion: Emotion
    var context: Context
    var trigger: Trigger
    var interruption = ""
    var recoveredAt: Date?
}

struct IfThenPlan: Codable, Identifiable {
    var id = UUID()
    var condition: String
    var action: String
}

struct QuitData: Codable {
    var schemaVersion = 1
    var profile = UserProfile()
    var checkIns: [DailyCheckIn] = []
    var urges: [UrgeSession] = []
    var episodes: [Episode] = []
    var plans: [IfThenPlan] = []
    var completedLessons: Set<Int> = []
    var reflections: [String: String] = [:]

    func validate() throws {
        let maximumDate = Date().addingTimeInterval(300)
        guard schemaVersion == 1 else { throw DataError.unsupportedVersion }
        guard profile.startedAt <= maximumDate,
              (0...23).contains(profile.sensitiveHour), (0...23).contains(profile.reminderHour),
              (0...59).contains(profile.reminderMinute), profile.name.count <= 100,
              profile.intention.count <= 2000, profile.contactName.count <= 100,
              profile.contactPhone.count <= 100,
              completedLessons.allSatisfy({ (1...42).contains($0) }),
              reflections.count <= 42, reflections.values.allSatisfy({ $0.count <= 5000 }),
              reflections.keys.allSatisfy({ Int($0).map { (1...42).contains($0) } ?? false }),
              checkIns.count <= 50000, urges.count <= 50000, episodes.count <= 50000, plans.count <= 100
        else { throw DataError.invalidData }
        guard Set(checkIns.map(\.id)).count == checkIns.count,
              Set(urges.map(\.id)).count == urges.count,
              Set(episodes.map(\.id)).count == episodes.count,
              Set(plans.map(\.id)).count == plans.count else { throw DataError.invalidData }
        guard checkIns.allSatisfy({ (0...10).contains($0.urge) && (1...3).contains($0.energy) && (1...3).contains($0.stress) && $0.date <= maximumDate }),
              urges.allSatisfy({ (0...10).contains($0.initial) && (0...10).contains($0.final) && $0.date <= maximumDate }),
              episodes.allSatisfy({ $0.date <= maximumDate && $0.interruption.count <= 2000 }),
              plans.allSatisfy({ !$0.condition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !$0.action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.condition.count <= 500 && $0.action.count <= 500 })
        else { throw DataError.invalidData }
        for episode in episodes {
            if let recovery = episode.recoveredAt, recovery < episode.date || recovery > maximumDate {
                throw DataError.invalidData
            }
        }
    }
}

enum DataError: LocalizedError {
    case unsupportedVersion, invalidData, tooLarge, lockedFile
    var errorDescription: String? {
        switch self {
        case .unsupportedVersion: "Cette sauvegarde vient d'une version différente de Quit. Mets l'app à jour avant de l'importer."
        case .invalidData: "Le fichier contient des données invalides. Tes données actuelles sont conservées."
        case .tooLarge: "Ce fichier dépasse la limite de 10 Mo."
        case .lockedFile: "La sauvegarde n'est pas accessible. Réessaie après avoir déverrouillé l'appareil."
        }
    }
}
