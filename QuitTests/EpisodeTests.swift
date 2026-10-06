import XCTest
@testable import Quit

@MainActor
final class EpisodeTests: XCTestCase {
    private let episodeDate = Date(timeIntervalSinceReferenceDate: 700_000_000)

    private func withVault(_ body: (LocalVault) throws -> Void) rethrows {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Quit-EpisodeTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try body(LocalVault(directory: directory))
    }

    private func episode() -> Episode {
        Episode(date: episodeDate, emotion: .lonely, context: .bed, trigger: .scrolling,
                interruption: "je prends mon téléphone au lit", nextAction: "je change de pièce")
    }

    private func snapshot(_ data: QuitData) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(data)
    }

    // V2 adds experience preferences; its envelope deliberately retains schemaVersion 1.
    private func legacyJSON(includeExperience: Bool) -> Data {
        let experience = includeExperience ? #", "experience": {"accent":"slate","appearance":"dark"}"# : ""
        return Data("""
        {
          "schemaVersion": 1,
          "profile": {
            "startedAt": 700000000, "name": "", "intention": "Mon intention",
            "goal": "stop", "sensitiveHour": 23, "contactName": "", "contactPhone": "",
            "biometricLock": false, "reminderEnabled": false, "reminderHour": 21,
            "reminderMinute": 0, "onboardingComplete": true
          },
          "checkIns": [], "urges": [],
          "episodes": [{
            "id": "00000000-0000-0000-0000-000000000123", "date": 700000000,
            "emotion": "lonely", "context": "bed", "trigger": "scrolling",
            "interruption": "Une analyse ancienne", "recoveredAt": 700000060
          }],
          "plans": [], "completedLessons": [1], "reflections": {"1":"Une réflexion"}
          \(experience)
        }
        """.utf8)
    }

    func testRawV1EpisodeWithoutNewFieldsDecodes() throws {
        try assertLegacyEpisode(includeExperience: false)
    }

    func testRawV2EpisodeWithoutNewFieldsDecodes() throws {
        try assertLegacyEpisode(includeExperience: true)
    }

    private func assertLegacyEpisode(includeExperience: Bool) throws {
        try withVault { vault in
            let bytes = legacyJSON(includeExperience: includeExperience)
            let decoded = try JSONDecoder().decode(QuitData.self, from: bytes)
            try decoded.validate()
            try FileManager.default.createDirectory(at: vault.directory, withIntermediateDirectories: true)
            try bytes.write(to: vault.url)
            let loaded = try XCTUnwrap(vault.load())
            let item = try XCTUnwrap(loaded.episodes.first)
            XCTAssertEqual(item.id, UUID(uuidString: "00000000-0000-0000-0000-000000000123"))
            XCTAssertEqual(item.date, episodeDate)
            XCTAssertEqual(item.emotion, .lonely)
            XCTAssertEqual(item.context, .bed)
            XCTAssertEqual(item.trigger, .scrolling)
            XCTAssertEqual(item.interruption, "Une analyse ancienne")
            XCTAssertNil(item.nextAction)
            XCTAssertNil(item.planID)
            XCTAssertEqual(item.recoveredAt, episodeDate.addingTimeInterval(60))
            XCTAssertEqual(loaded.completedLessons, [1])
            XCTAssertEqual(loaded.reflections["1"], "Une réflexion")
            XCTAssertEqual(loaded.experience.accent, includeExperience ? .slate : .sage)
            XCTAssertEqual(loaded.experience.appearance, includeExperience ? .dark : .system)
            XCTAssertEqual(try snapshot(loaded), try snapshot(decoded))
        }
    }

    func testAllEpisodeFieldsAndLinkedPlanSurviveDiskAndJSONRoundTrip() throws {
        try withVault { vault in
            let store = AppStore(vault: vault)
            let item = episode()
            let recovery = episodeDate.addingTimeInterval(60)
            XCTAssertTrue(store.saveEpisode(item, keepPlan: true, returnedToPlan: true, now: recovery))
            let saved = try XCTUnwrap(store.data.episodes.first)
            let plan = try XCTUnwrap(store.data.plans.first)
            let loaded = try XCTUnwrap(vault.load())
            let decoded = try JSONDecoder().decode(QuitData.self, from: store.exportData())
            for data in [loaded, decoded] {
                let restored = try XCTUnwrap(data.episodes.first)
                XCTAssertEqual(restored.id, item.id)
                XCTAssertEqual(restored.date, item.date)
                XCTAssertEqual(restored.emotion, item.emotion)
                XCTAssertEqual(restored.context, item.context)
                XCTAssertEqual(restored.trigger, item.trigger)
                XCTAssertEqual(restored.interruption, item.interruption)
                XCTAssertEqual(restored.nextAction, item.nextAction)
                XCTAssertEqual(restored.planID, plan.id)
                XCTAssertEqual(restored.recoveredAt, recovery)
                XCTAssertEqual(data.plans.first?.id, plan.id)
                XCTAssertEqual(data.plans.first?.condition, item.interruption)
                XCTAssertEqual(data.plans.first?.action, item.nextAction)
                XCTAssertEqual(try snapshot(data), try snapshot(store.data))
            }
            XCTAssertEqual(saved.planID, plan.id)
        }
    }

    func testDecliningRulePreservesNextActionWithoutCreatingPlan() throws {
        try withVault { vault in
            let store = AppStore(vault: vault)
            var item = episode()
            item.nextAction = "  mon action personnelle  \n"
            XCTAssertTrue(store.saveEpisode(item, keepPlan: false, returnedToPlan: false, now: episodeDate))
            XCTAssertTrue(store.data.plans.isEmpty)
            XCTAssertNil(store.data.episodes.first?.planID)
            XCTAssertEqual(store.data.episodes.first?.nextAction, "mon action personnelle")
            XCTAssertEqual(try vault.load()?.episodes.first?.nextAction, "mon action personnelle")
        }
    }

    func testOptInCreatesRuleOnceAndEditingPreservesItsUUID() throws {
        try withVault { vault in
            let store = AppStore(vault: vault)
            var item = episode()
            XCTAssertTrue(store.saveEpisode(item, keepPlan: false, returnedToPlan: false, now: episodeDate))
            XCTAssertTrue(store.data.plans.isEmpty)
            XCTAssertTrue(store.saveEpisode(item, keepPlan: true, returnedToPlan: false, now: episodeDate))
            let planID = try XCTUnwrap(store.data.plans.first?.id)
            XCTAssertTrue(store.saveEpisode(item, keepPlan: true, returnedToPlan: false, now: episodeDate))
            item.interruption = "je remarque mon automatisme"
            item.nextAction = "je vais marcher"
            XCTAssertTrue(store.saveEpisode(item, keepPlan: true, returnedToPlan: false, now: episodeDate))
            XCTAssertEqual(store.data.episodes.count, 1)
            XCTAssertEqual(store.data.episodes.first?.id, item.id)
            XCTAssertEqual(store.data.episodes.first?.planID, planID)
            XCTAssertEqual(store.data.plans.count, 1)
            XCTAssertEqual(store.data.plans.first?.id, planID)
            XCTAssertEqual(store.data.plans.first?.condition, item.interruption)
            XCTAssertEqual(store.data.plans.first?.action, item.nextAction)
            XCTAssertEqual(try vault.load()?.plans.first?.id, planID)
        }
    }

    func testMatchingRuleIsReusedAcrossEpisodesWithoutDuplication() throws {
        try withVault { vault in
            let store = AppStore(vault: vault)
            let first = episode()
            let matching = IfThenPlan(condition: first.interruption, action: try XCTUnwrap(first.nextAction))
            XCTAssertTrue(store.update { $0.plans = [matching] })
            XCTAssertTrue(store.saveEpisode(first, keepPlan: true, returnedToPlan: false, now: episodeDate))
            var second = episode()
            second.interruption = "  \(first.interruption)  "
            second.nextAction = "  \(try XCTUnwrap(first.nextAction))  "
            XCTAssertTrue(store.saveEpisode(second, keepPlan: true, returnedToPlan: false, now: episodeDate))
            XCTAssertEqual(store.data.episodes.count, 2)
            XCTAssertEqual(store.data.plans.count, 1)
            XCTAssertEqual(store.data.plans.first?.id, matching.id)
            XCTAssertTrue(store.data.episodes.allSatisfy { $0.planID == matching.id })
        }
    }

    func testLongInterruptionWithoutRuleIsPreserved() throws {
        try withVault { vault in
            let store = AppStore(vault: vault)
            var item = episode()
            item.interruption = String(repeating: "é", count: 2_000)
            XCTAssertTrue(store.saveEpisode(item, keepPlan: false, returnedToPlan: false, now: episodeDate))
            XCTAssertEqual(store.data.episodes.first?.interruption, item.interruption)
            XCTAssertEqual(try vault.load()?.episodes.first?.interruption, item.interruption)
            XCTAssertTrue(store.data.plans.isEmpty)
        }
    }

    func testAtPlanLimitAnalysisWithoutRuleSucceedsAndOptInFailsAtomically() throws {
        try withVault { vault in
            let store = AppStore(vault: vault)
            XCTAssertTrue(store.update { data in
                data.plans = (0..<100).map { IfThenPlan(condition: "condition \($0)", action: "action \($0)") }
            })
            var item = episode()
            XCTAssertTrue(store.saveEpisode(item, keepPlan: false, returnedToPlan: false, now: episodeDate))
            XCTAssertEqual(store.data.plans.count, 100)
            XCTAssertEqual(store.data.episodes.first?.nextAction, item.nextAction)
            let before = try snapshot(store.data)
            let diskBefore = try Data(contentsOf: vault.url)
            item.nextAction = "une action modifiée qui ne doit pas être enregistrée"
            XCTAssertFalse(store.saveEpisode(item, keepPlan: true, returnedToPlan: true,
                                            now: episodeDate.addingTimeInterval(60)))
            let message = try XCTUnwrap(store.errorMessage)
            XCTAssertTrue(message.contains("100"))
            XCTAssertTrue(message.contains("sans ajouter de règle"))
            XCTAssertEqual(try snapshot(store.data), before)
            XCTAssertEqual(try Data(contentsOf: vault.url), diskBefore)
            XCTAssertEqual(store.data.episodes.count, 1)
            XCTAssertNil(store.data.episodes.first?.recoveredAt)
        }
    }

    func testMovingEpisodeAfterHistoricalRecoveryFailsAtomically() throws {
        try withVault { vault in
            let store = AppStore(vault: vault)
            var item = episode()
            let recovery = episodeDate.addingTimeInterval(60)
            XCTAssertTrue(store.saveEpisode(item, keepPlan: true, returnedToPlan: true, now: recovery))
            let before = try snapshot(store.data)
            let diskBefore = try Data(contentsOf: vault.url)
            item.date = recovery.addingTimeInterval(1)
            item.nextAction = "une autre action"
            XCTAssertFalse(store.saveEpisode(item, keepPlan: true, returnedToPlan: true,
                                            now: recovery.addingTimeInterval(600)))
            let message = try XCTUnwrap(store.errorMessage)
            XCTAssertTrue(message.contains("date"))
            XCTAssertTrue(message.contains("retour au plan"))
            XCTAssertEqual(try snapshot(store.data), before)
            XCTAssertEqual(try Data(contentsOf: vault.url), diskBefore)
            XCTAssertEqual(store.data.episodes.first?.recoveredAt, recovery)
        }
    }

    func testRecoveryTimestampStaysStableDuringEditingAndRepeatedResume() throws {
        try withVault { vault in
            let store = AppStore(vault: vault)
            var item = episode()
            let recovery = episodeDate.addingTimeInterval(60)
            XCTAssertTrue(store.saveEpisode(item, keepPlan: false, returnedToPlan: false, now: episodeDate))
            XCTAssertTrue(store.resumePlan(after: item.id, now: recovery))
            XCTAssertEqual(store.data.episodes.first?.recoveredAt, recovery)
            XCTAssertTrue(store.resumePlan(after: item.id, now: recovery.addingTimeInterval(600)))
            item.interruption = "une analyse affinée"
            item.recoveredAt = recovery.addingTimeInterval(1_200)
            XCTAssertTrue(store.saveEpisode(item, keepPlan: false, returnedToPlan: true,
                                           now: recovery.addingTimeInterval(1_800)))
            XCTAssertTrue(store.resumePlan(after: item.id, now: recovery.addingTimeInterval(2_400)))
            XCTAssertEqual(store.data.episodes.first?.recoveredAt, recovery)
            XCTAssertEqual(try vault.load()?.episodes.first?.recoveredAt, recovery)
            XCTAssertEqual(store.data.episodes.first?.interruption, item.interruption)
        }
    }

    func testSuggestionsAreDeterministicAndPrioritizeBedThenLonelinessThenScrolling() {
        let cases: [(Emotion, Context, Trigger, String, String)] = [
            (.lonely, .bed, .scrolling,
             "je remarque un contenu qui déclenche mon envie",
             "je pose mon téléphone hors de la chambre et je change de pièce"),
            (.calm, .bed, .habit,
             "je prends mon téléphone au lit",
             "je pose mon téléphone hors de la chambre et je change de pièce"),
            (.lonely, .desk, .scrolling,
             "je remarque un contenu qui déclenche mon envie",
             "je propose à une personne de confiance de parler quelques minutes"),
            (.calm, .desk, .scrolling,
             "je remarque un contenu qui déclenche mon envie",
             "je ferme le contenu et je pose mon téléphone hors de portée"),
            (.calm, .elsewhere, .habit,
             "je remarque le début de mon automatisme",
             "je change de pièce et je prends une minute pour observer mon envie")
        ]
        for (emotion, context, trigger, condition, action) in cases {
            for _ in 0..<3 {
                let suggestion = EpisodeSuggestion(emotion: emotion, context: context, trigger: trigger)
                XCTAssertEqual(suggestion.condition, condition)
                XCTAssertEqual(suggestion.action, action)
            }
        }
    }
}
