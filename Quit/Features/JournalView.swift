import SwiftUI

struct JournalView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedEpisode: Episode?
    @State private var deleteID: UUID?
    var body: some View {
        ScreenContent {
            if store.data.episodes.isEmpty && store.data.urges.isEmpty && store.data.checkIns.isEmpty {
                ContentUnavailableView("Un espace pour comprendre", systemImage: "book.closed", description: Text("Tes check-ins, envies et épisodes apparaîtront ici."))
            }
            ForEach(store.data.episodes.sorted { $0.date > $1.date }) { episode in
                QuitCard {
                    Text(episode.date, format: .dateTime.day().month().hour().minute()).font(.footnote).foregroundStyle(QuitTheme.secondary)
                    Text("Épisode · \(episode.emotion.title)").font(.headline)
                    Text("\(episode.context.title) · \(episode.trigger.title)").font(.subheadline).foregroundStyle(QuitTheme.secondary)
                    if !episode.interruption.isEmpty { Text(episode.interruption) }
                    let layout = dynamicTypeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                        : AnyLayout(HStackLayout())
                    layout {
                        Button("Comprendre") { selectedEpisode = episode }.frame(minHeight: 44)
                        if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                        if episode.recoveredAt == nil {
                            Button("Reprendre mon plan") { store.update { data in
                                if let index = data.episodes.firstIndex(where: { $0.id == episode.id }) { data.episodes[index].recoveredAt = Date() }
                            }}.frame(minHeight: 44)
                        } else { Label("Plan repris", systemImage: "checkmark").font(.caption) }
                    }
                    Button("Supprimer cet épisode", role: .destructive) { deleteID = episode.id }.font(.footnote).frame(minHeight: 44)
                }
            }
            ForEach(store.data.urges.sorted { $0.date > $1.date }.prefix(50)) { session in
                QuitCard {
                    Text(session.date, format: .dateTime.day().month().hour().minute()).font(.footnote).foregroundStyle(QuitTheme.secondary)
                    Label("Envie · \(session.initial) → \(session.final)", systemImage: "water.waves").font(.headline)
                    Text("\(session.strategy.title) · \(session.outcome.title)").font(.subheadline).foregroundStyle(QuitTheme.secondary)
                }
            }
            ForEach(store.data.checkIns.sorted { $0.date > $1.date }.prefix(30)) { item in
                QuitCard {
                    Text(item.date, format: .dateTime.day().month()).font(.footnote).foregroundStyle(QuitTheme.secondary)
                    Text("Check-in · \(item.emotion.title)").font(.headline)
                    Text("Envie \(item.urge)/10 · \(item.aligned.map { $0 ? "Journée alignée" : "Objectif non atteint" } ?? "Bilan à préciser")")
                        .font(.subheadline).foregroundStyle(QuitTheme.secondary)
                }
            }
        }
        .navigationTitle("Mon journal").navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedEpisode) { EpisodeView(existingID: $0.id) }
        .confirmationDialog("Supprimer cet épisode ?", isPresented: Binding(get: { deleteID != nil }, set: { if !$0 { deleteID = nil } }), titleVisibility: .visible) {
            Button("Supprimer", role: .destructive) { if let id = deleteID { store.update { $0.episodes.removeAll { $0.id == id } } }; deleteID = nil }
            Button("Annuler", role: .cancel) { deleteID = nil }
        }
    }
}
