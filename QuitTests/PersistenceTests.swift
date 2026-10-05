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
}
