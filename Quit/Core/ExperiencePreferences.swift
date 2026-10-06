import Foundation

enum AccentTheme: String, Codable, CaseIterable, Identifiable, Sendable {
    case sage, slate, sand
    var id: Self { self }
    var title: String {
        switch self { case .sage: "Sauge"; case .slate: "Brume"; case .sand: "Sable" }
    }
}

enum AppAppearance: String, Codable, CaseIterable, Identifiable, Sendable {
    case system, light, dark
    var id: Self { self }
    var title: String {
        switch self { case .system: "Automatique"; case .light: "Clair"; case .dark: "Sombre" }
    }
}

enum ObservationDuration: Int, Codable, CaseIterable, Identifiable, Sendable {
    case ninetySeconds = 90, threeMinutes = 180, fiveMinutes = 300
    var id: Self { self }
    var seconds: Int { rawValue }
    var title: String {
        switch self { case .ninetySeconds: "90 s"; case .threeMinutes: "3 min"; case .fiveMinutes: "5 min" }
    }
}

struct ExperiencePreferences: Codable, Equatable, Sendable {
    var accent: AccentTheme = .sage
    var appearance: AppAppearance = .system
    var reduceAnimations = false
    var haptics = true
    var observationDuration: ObservationDuration = .ninetySeconds

    init() { }
    private enum CodingKeys: String, CodingKey {
        case accent, appearance, reduceAnimations, haptics, observationDuration
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        accent = try values.decodeIfPresent(AccentTheme.self, forKey: .accent) ?? .sage
        appearance = try values.decodeIfPresent(AppAppearance.self, forKey: .appearance) ?? .system
        reduceAnimations = try values.decodeIfPresent(Bool.self, forKey: .reduceAnimations) ?? false
        haptics = try values.decodeIfPresent(Bool.self, forKey: .haptics) ?? true
        observationDuration = try values.decodeIfPresent(ObservationDuration.self, forKey: .observationDuration) ?? .ninetySeconds
    }
}
