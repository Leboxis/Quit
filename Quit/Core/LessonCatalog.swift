import Foundation

struct Lesson: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let body: String
    let prompt: String
    let action: String
    let source: String
    var week: Int { (id - 1) / 7 + 1 }
}

enum LessonCatalog {
    static let weekTitles = ["Comprendre mon cycle", "Mes déclencheurs", "Traverser une envie", "Pensées et valeurs", "Mon environnement", "Apprendre et continuer"]
    static let weekDescriptions = ["Observer sans se juger.", "Repérer ce qui précède l'envie.", "Créer de l'espace avant d'agir.", "Choisir une direction qui me ressemble.", "Rendre mes choix plus faciles.", "Préparer les moments difficiles."]
    static let lessons: [Lesson] = {
        guard let url = Bundle.main.url(forResource: "lessons", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let lessons = try? JSONDecoder().decode([Lesson].self, from: data) else { return [] }
        return lessons
    }()
}
