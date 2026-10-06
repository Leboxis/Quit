import XCTest
@testable import Quit

@MainActor
final class PersistenceTests: XCTestCase {
    func testSavingAndReloadingPreservesPersonalData() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let disk = LocalVault(directory: directory)
        var data = QuitData()
        data.profile.intention = "Retrouver mes soirées"
        try disk.save(data)
        XCTAssertEqual(try disk.load()?.profile.intention, data.profile.intention)
    }

    func testCorruptFileIsNotOverwritten() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("quit-v1.json")
        try Data("broken".utf8).write(to: url)
        let store = AppStore(vault: LocalVault(directory: directory))
        XCTAssertNotNil(store.loadError)
        XCTAssertFalse(store.update { $0.profile.intention = "New" })
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "broken")
    }

    func testDailyCheckInUpdatesExistingDayInsteadOfDuplicating() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = AppStore(vault: LocalVault(directory: directory))
        let now = Date()
        XCTAssertTrue(store.saveCheckIn(DailyCheckIn(date: now, emotion: .calm, energy: 2, stress: 1, urge: 2, aligned: true)))
        XCTAssertTrue(store.saveCheckIn(DailyCheckIn(date: now, emotion: .tired, energy: 1, stress: 2, urge: 5, aligned: nil)))
        XCTAssertEqual(store.data.checkIns.count, 1)
        XCTAssertEqual(store.data.checkIns.first?.urge, 5)
    }

    func testInvalidImportLeavesExistingDataUntouched() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = AppStore(vault: LocalVault(directory: directory))
        XCTAssertTrue(store.update { $0.profile.intention = "Existing" })
        XCTAssertThrowsError(try store.importData(Data("{}".utf8)))
        XCTAssertEqual(store.data.profile.intention, "Existing")
    }

    func testRelaunchPreservesEveryKindOfRecordAndPreferences() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let vault = LocalVault(directory: directory)
        let store = AppStore(vault: vault)
        let now = Date()
        XCTAssertTrue(store.update {
            $0.profile.onboardingComplete = true
            $0.profile.intention = "Retrouver mes soirées"
            $0.profile.contactName = "Une personne de confiance"
            $0.checkIns = [DailyCheckIn(date: now, emotion: .calm, energy: 2, stress: 1, urge: 3, aligned: nil)]
            $0.urges = [UrgeSession(date: now, initial: 7, final: 3, strategy: .walk, outcome: .passed, emotion: .tired)]
            $0.episodes = [Episode(date: now, emotion: .tired, context: .bed, trigger: .habit)]
            $0.plans = [IfThenPlan(condition: "Téléphone au lit", action: "Le poser dans la cuisine")]
            $0.completedLessons = [1, 7, 14]
            $0.reflections = ["7": "Un geste utile"]
            $0.experience.accent = .sand
            $0.experience.observationDuration = .fiveMinutes
        })
        let reloaded = AppStore(vault: vault)
        XCTAssertNil(reloaded.loadError)
        XCTAssertEqual(reloaded.data.profile.intention, store.data.profile.intention)
        XCTAssertTrue(reloaded.data.profile.onboardingComplete)
        XCTAssertEqual(reloaded.data.profile.contactName, store.data.profile.contactName)
        XCTAssertEqual(reloaded.data.checkIns.map(\.id), store.data.checkIns.map(\.id))
        XCTAssertNil(reloaded.data.checkIns.first?.aligned)
        XCTAssertEqual(reloaded.data.urges.map(\.id), store.data.urges.map(\.id))
        XCTAssertEqual(reloaded.data.urges.first?.final, 3)
        XCTAssertEqual(reloaded.data.episodes.map(\.id), store.data.episodes.map(\.id))
        XCTAssertEqual(reloaded.data.plans.map(\.id), store.data.plans.map(\.id))
        XCTAssertEqual(reloaded.data.plans.first?.action, store.data.plans.first?.action)
        XCTAssertEqual(reloaded.data.completedLessons, store.data.completedLessons)
        XCTAssertEqual(reloaded.data.reflections, store.data.reflections)
        XCTAssertEqual(reloaded.data.experience, store.data.experience)
    }

    func testFailedWriteLeavesInMemoryDataUnchanged() throws {
        let parent = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: parent) }
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        let blockedDirectory = parent.appendingPathComponent("file-instead-of-directory")
        try Data("keep".utf8).write(to: blockedDirectory)
        let store = AppStore(vault: LocalVault(directory: blockedDirectory))
        XCTAssertFalse(store.update { $0.profile.intention = "Must not appear saved" })
        XCTAssertEqual(store.data.profile.intention, "")
        XCTAssertNotNil(store.errorMessage)
        XCTAssertEqual(try String(contentsOf: blockedDirectory, encoding: .utf8), "keep")
    }

    func testImportKeepsDeviceLockAndRequiresReminderReactivation() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = AppStore(vault: LocalVault(directory: directory))
        XCTAssertTrue(store.update { $0.profile.biometricLock = true })
        var backup = QuitData()
        backup.profile.reminderEnabled = true
        backup.profile.reminderHour = 19
        backup.completedLessons = [4]
        try store.importData(JSONEncoder().encode(backup))
        XCTAssertTrue(store.data.profile.biometricLock)
        XCTAssertFalse(store.data.profile.reminderEnabled)
        XCTAssertEqual(store.data.profile.reminderHour, 19)
        XCTAssertEqual(store.data.completedLessons, [4])
    }
}
