import Foundation
import Observation

@MainActor @Observable
final class AppStore {
    private(set) var data: QuitData
    private(set) var loadError: String?
    var errorMessage: String?
    @ObservationIgnored private let vault: LocalVault

    init(vault: LocalVault = LocalVault()) {
        self.vault = vault
        do {
            data = try vault.load() ?? QuitData()
        } catch {
            data = QuitData()
            loadError = "Ta sauvegarde n'a pas pu être ouverte. Elle a été conservée. " + error.localizedDescription
        }
    }

    @discardableResult
    func update(_ mutation: (inout QuitData) -> Void) -> Bool {
        guard loadError == nil else {
            errorMessage = loadError
            return false
        }
        var next = data
        mutation(&next)
        do {
            try vault.save(next)
            data = next
            return true
        } catch {
            errorMessage = "La modification n'a pas été enregistrée. " + error.localizedDescription
            return false
        }
    }

    @discardableResult
    func saveCheckIn(_ item: DailyCheckIn) -> Bool {
        update { data in
            if let index = data.checkIns.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: item.date) }) {
                var revised = item
                revised.id = data.checkIns[index].id
                data.checkIns[index] = revised
            } else {
                data.checkIns.append(item)
            }
        }
    }

    /// Save analysis and its optional rule in one transaction; never duplicate a linked rule.
    @discardableResult
    func saveEpisode(_ item: Episode, keepPlan: Bool, returnedToPlan: Bool, now: Date = Date()) -> Bool {
        var episode = item
        episode.interruption = item.interruption.trimmingCharacters(in: .whitespacesAndNewlines)
        episode.nextAction = item.nextAction?.trimmingCharacters(in: .whitespacesAndNewlines)
        let previous = data.episodes.first { $0.id == item.id }
        episode.recoveredAt = returnedToPlan ? previous?.recoveredAt ?? now : nil
        if let recovery = episode.recoveredAt, recovery < episode.date {
            errorMessage = "La date de l’épisode doit précéder le retour au plan. Corrige la date ou décoche le retour au plan."
            return false
        }
        let linked = (previous?.planID).flatMap { id in data.plans.first { $0.id == id } }
        let matching = data.plans.contains { $0.condition == episode.interruption && $0.action == (episode.nextAction ?? "") }
        if keepPlan && !episode.interruption.isEmpty && !(episode.nextAction ?? "").isEmpty && linked == nil && !matching && data.plans.count >= 100 {
            errorMessage = "Tes 100 plans sont conservés. Enregistre l’analyse sans ajouter de règle, ou retire un plan."
            return false
        }
        return update { data in
            let action = episode.nextAction ?? ""
            if keepPlan && !episode.interruption.isEmpty && !action.isEmpty {
                if let id = previous?.planID, let index = data.plans.firstIndex(where: { $0.id == id }) {
                    data.plans[index].condition = episode.interruption
                    data.plans[index].action = action
                    episode.planID = id
                } else if let matching = data.plans.first(where: { $0.condition == episode.interruption && $0.action == action }) {
                    episode.planID = matching.id
                } else {
                    let plan = IfThenPlan(condition: episode.interruption, action: action)
                    data.plans.append(plan)
                    episode.planID = plan.id
                }
            } else {
                // Declining a suggestion never deletes a previously chosen personal rule.
                episode.planID = previous?.planID
            }
            if let index = data.episodes.firstIndex(where: { $0.id == episode.id }) {
                data.episodes[index] = episode
            } else {
                data.episodes.append(episode)
            }
        }
    }

    @discardableResult
    func resumePlan(after episodeID: UUID, now: Date = Date()) -> Bool {
        guard data.episodes.contains(where: { $0.id == episodeID }) else {
            errorMessage = "Cet épisode n’est plus disponible. Retourne au journal."
            return false
        }
        return update { data in
            if let index = data.episodes.firstIndex(where: { $0.id == episodeID }), data.episodes[index].recoveredAt == nil {
                data.episodes[index].recoveredAt = max(now, data.episodes[index].date)
            }
        }
    }

    func reload() {
        do {
            data = try vault.load() ?? QuitData()
            loadError = nil
        } catch {
            loadError = "La sauvegarde reste inaccessible. " + error.localizedDescription
        }
    }

    func importData(_ bytes: Data) throws {
        guard bytes.count <= 10 * 1024 * 1024 else { throw DataError.tooLarge }
        var imported = try JSONDecoder().decode(QuitData.self, from: bytes)
        try imported.validate()
        // Device permissions are not transferable through a backup file.
        imported.profile.biometricLock = data.profile.biometricLock
        imported.profile.reminderEnabled = false
        try vault.save(imported)
        data = imported
        loadError = nil
    }

    func exportData() throws -> Data {
        guard loadError == nil else { throw DataError.lockedFile }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(data)
    }

    func eraseEverything() throws {
        let blank = QuitData()
        try vault.save(blank)
        data = blank
        loadError = nil
    }

    func suggestions(for emotion: Emotion) -> [Strategy] {
        let defaults: [Strategy] = emotion == .lonely ? [.connect, .move, .walk] : [.move, .walk, .connect]
        let proven = ProgressSnapshot(data: data).strategies.filter { $0.count >= 3 && $0.reduction > 0 }.map(\.strategy)
        return Array((proven + defaults).reduce(into: [Strategy]()) { result, strategy in
            if !result.contains(strategy) { result.append(strategy) }
        }.prefix(3))
    }
}
