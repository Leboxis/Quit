import Foundation

struct JourneyPath: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let overview: String
    let symbol: String
    let lessonIDs: [Int]
    var isFullCourse: Bool { id == "foundations" }

    var lessons: [Lesson] {
        let available = Dictionary(uniqueKeysWithValues: LessonCatalog.lessons.map { ($0.id, $0) })
        return lessonIDs.compactMap { available[$0] }
    }
    func completedCount(in completed: Set<Int>) -> Int {
        lessonIDs.filter { completed.contains($0) }.count
    }
    func nextLesson(in completed: Set<Int>) -> Lesson? {
        lessons.first { !completed.contains($0.id) }
    }
}

enum JourneyCatalog {
    // Paths are different ways through the same exercises. Keeping the original
    // lesson IDs preserves completion, reflections and older JSON backups.
    static let paths: [JourneyPath] = [
        JourneyPath(id: "foundations", title: "Les fondamentaux", subtitle: "6 semaines · 42 étapes",
                    overview: "Comprendre tes habitudes, traverser les envies et préparer la suite : le parcours complet.",
                    symbol: "leaf", lessonIDs: Array(1...42)),
        JourneyPath(id: "urges", title: "Traverser une envie", subtitle: "7 étapes · 2 à 5 min par étape",
                    overview: "Créer une pause, observer ce que tu ressens et choisir une action lorsque l'envie arrive.",
                    symbol: "water.waves", lessonIDs: Array(15...21)),
        JourneyPath(id: "environment", title: "Mon environnement", subtitle: "7 étapes · 2 à 5 min par étape",
                    overview: "Préparer ton téléphone, tes soirées et tes contacts pour rendre tes prochains choix plus faciles.",
                    symbol: "shield", lessonIDs: Array(29...35)),
        JourneyPath(id: "recovery", title: "Après un écart", subtitle: "7 étapes · 2 à 5 min par étape",
                    overview: "Comprendre un épisode, reprendre ton plan et conserver ce que tu as appris.",
                    symbol: "arrow.uturn.forward", lessonIDs: Array(36...42))
    ]
}
