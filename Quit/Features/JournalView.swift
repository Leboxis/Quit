import SwiftUI

struct JournalView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedEpisode: Episode?
    @State private var deleteID: UUID?
    @State private var filter: JournalFilter = .all
    @State private var visibleCount = 20

    init(showCheckInsOnly: Bool = false) {
        _filter = State(initialValue: showCheckInsOnly ? .checkIns : .all)
    }

    private enum JournalFilter: String, CaseIterable, Identifiable {
        case all = "Tous"
        case episodes = "Épisodes"
        case urges = "Envies"
        case checkIns = "Check-ins"
        var id: String { rawValue }
    }

    private enum JournalEntry: Identifiable {
        case episode(Episode)
        case urge(UrgeSession)
        case checkIn(DailyCheckIn)

        // Namespace the original identifiers; different record types may share a UUID.
        var id: String {
            switch self {
            case .episode(let item): return "episode-\(item.id.uuidString)"
            case .urge(let item): return "urge-\(item.id.uuidString)"
            case .checkIn(let item): return "checkin-\(item.id.uuidString)"
            }
        }
        var date: Date {
            switch self {
            case .episode(let item): return item.date
            case .urge(let item): return item.date
            case .checkIn(let item): return item.date
            }
        }
    }

    private var entries: [JournalEntry] {
        var result: [JournalEntry] = []
        if filter == .all || filter == .episodes {
            result += store.data.episodes.map { .episode($0) }
        }
        if filter == .all || filter == .urges {
            result += store.data.urges.map { .urge($0) }
        }
        if filter == .all || filter == .checkIns {
            result += store.data.checkIns.map { .checkIn($0) }
        }
        // Most recent first, with a stable tie-breaker for identical timestamps.
        return result.sorted { $0.date == $1.date ? $0.id < $1.id : $0.date > $1.date }
    }

    var body: some View {
        let history = entries
        ScreenContent {
            Menu {
                Picker("Filtrer le journal", selection: $filter) {
                    ForEach(JournalFilter.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            } label: {
                Label("Filtre : \(filter.rawValue)", systemImage: "line.3.horizontal.decrease.circle")
                    .font(.subheadline.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 44)
            }
            .accessibilityLabel("Filtrer le journal")
            .accessibilityValue(filter.rawValue)
            .accessibilityIdentifier("journal.filter")
            if history.isEmpty {
                if filter == .all {
                    ContentUnavailableView("Un espace pour comprendre", systemImage: "book.closed", description: Text("Tes check-ins, envies et épisodes apparaîtront ici."))
                } else {
                    ContentUnavailableView("Aucune entrée", systemImage: "line.3.horizontal.decrease.circle", description: Text("Aucune entrée pour ce filtre. Choisis Tous pour voir le reste du journal."))
                }
            }
            LazyVStack(alignment: .leading, spacing: 14) {
                ForEach(history.prefix(visibleCount)) { entry in
                    entryCard(entry)
                }
            }
            if visibleCount < history.count {
                Button("Charger plus") { visibleCount += 20 }
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .accessibilityIdentifier("journal.more")
            }
        }
        .navigationTitle("Mon journal").navigationBarTitleDisplayMode(.inline)
        .onChange(of: filter) { _, _ in visibleCount = 20 }
        .sheet(item: $selectedEpisode) { EpisodeView(existingID: $0.id) }
        .confirmationDialog("Supprimer cet épisode ?", isPresented: Binding(get: { deleteID != nil }, set: { if !$0 { deleteID = nil } }), titleVisibility: .visible) {
            Button("Supprimer", role: .destructive) { if let id = deleteID { store.update { $0.episodes.removeAll { $0.id == id } } }; deleteID = nil }
            Button("Annuler", role: .cancel) { deleteID = nil }
        }
    }

    @ViewBuilder
    private func entryCard(_ entry: JournalEntry) -> some View {
        QuitCard {
            Text(entry.date, format: .dateTime.day().month().year().hour().minute())
                .font(.footnote).foregroundStyle(QuitTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
            switch entry {
            case .episode(let episode):
                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                    : AnyLayout(HStackLayout(alignment: .top))
                layout {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("\(episode.context.title) · \(episode.trigger.title)")
                                .font(.subheadline).foregroundStyle(QuitTheme.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            if !episode.interruption.isEmpty {
                                Text(episode.interruption).fixedSize(horizontal: false, vertical: true)
                            }
                            if let action = episode.nextAction, !action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("Prochain geste : \(action)")
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Button("Comprendre") { selectedEpisode = episode }
                                .fixedSize(horizontal: false, vertical: true).frame(minHeight: 44)
                                .accessibilityIdentifier("journal.edit.\(episode.id.uuidString)")
                            if episode.recoveredAt == nil {
                                Button("Reprendre mon plan") {
                                    store.resumePlan(after: episode.id)
                                }.fixedSize(horizontal: false, vertical: true).frame(minHeight: 44)
                                    .accessibilityIdentifier("journal.resume.\(episode.id.uuidString)")
                            } else {
                                Label("Plan repris", systemImage: "checkmark").font(.subheadline)
                            }
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } label: {
                        QuitSectionTitle(title: "Épisode · \(episode.emotion.title)", symbol: "arrow.uturn.forward", tone: .preparation)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("journal.episode.\(episode.id.uuidString)")
                    Menu {
                        Button("Supprimer cet épisode", role: .destructive) { deleteID = episode.id }
                    } label: {
                        Image(systemName: "ellipsis").frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Actions de cet épisode")
                }
            case .urge(let session):
                Label("Envie · \(session.initial) → \(session.final)", systemImage: "water.waves")
                    .font(.headline).foregroundStyle(QuitTone.reflection.color).fixedSize(horizontal: false, vertical: true)
                Text("\(session.strategy.title) · \(session.outcome.title)")
                    .font(.subheadline).foregroundStyle(QuitTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            case .checkIn(let item):
                QuitSectionTitle(title: "Check-in · \(item.emotion.title)", symbol: "checkmark.circle")
                Text("Envie \(item.urge)/10 · \(item.aligned.map { $0 ? "Journée alignée" : "Objectif non atteint" } ?? "Bilan à préciser")")
                    .font(.subheadline).foregroundStyle(QuitTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
