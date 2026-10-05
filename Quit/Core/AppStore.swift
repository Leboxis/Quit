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
