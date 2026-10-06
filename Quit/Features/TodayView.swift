import SwiftUI

struct TodayView: View {
    @Environment(\.quitAccent) private var accent
    @Environment(AppStore.self) private var store
    @State private var showCheckIn = false
    @State private var showEpisode = false
    private var todayCheckIn: DailyCheckIn? {
        store.data.checkIns.first { Calendar.current.isDateInToday($0.date) }
    }
    private var journeyDay: Int {
        max(1, (Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: store.data.profile.startedAt),
                                              to: Calendar.current.startOfDay(for: Date())).day ?? 0) + 1)
    }

    var body: some View {
        ScreenContent {
            Text(Date(), format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.subheadline).foregroundStyle(QuitTheme.secondary)
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("TON ESPACE PERSONNEL").font(.caption.weight(.medium)).tracking(1.2)
                    Spacer()
                    Text("Jour \(journeyDay)").font(.caption.weight(.medium)).monospacedDigit()
                }.foregroundStyle(accent.color)
                Text(store.data.profile.name.isEmpty ? "Un geste à la fois." : "Bonjour, \(store.data.profile.name).")
                    .font(.title2.weight(.medium))
                ContourArtwork().frame(height: 72)
            }
            .padding(22)
            .background(LinearGradient(colors: [accent.soft, QuitTheme.background], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            QuitCard(tinted: true) {
                Label("Ton intention", systemImage: "leaf").font(.headline)
                Text(store.data.profile.intention.isEmpty ? "Retrouver de la liberté dans mes choix." : "« \(store.data.profile.intention) »")
                    .font(.title3).fixedSize(horizontal: false, vertical: true)
            }
            QuitCard {
                HStack {
                    Text(todayCheckIn == nil ? "Comment tu te sens ?" : "Ton check-in du jour").font(.headline)
                    Spacer()
                    if todayCheckIn != nil { Image(systemName: "checkmark.circle.fill").foregroundStyle(accent.color) }
                }
                if let checkIn = todayCheckIn {
                    Text("\(checkIn.emotion.title) · Envie \(checkIn.urge)/10").foregroundStyle(QuitTheme.secondary)
                } else {
                    Text("10 secondes, juste pour toi.").foregroundStyle(QuitTheme.secondary)
                }
                QuitPrimaryButton(title: todayCheckIn == nil ? "Faire mon check-in" : "Actualiser mon check-in") { showCheckIn = true }
                    .accessibilityIdentifier("checkin.open")
            }
            QuitCard {
                Text("Un geste pour aujourd'hui").font(.headline)
                if let plan = store.data.plans.first {
                    Text("Si \(plan.condition.lowercased())…").foregroundStyle(QuitTheme.secondary)
                    Text(plan.action).font(.title3.weight(.medium))
                } else {
                    Text("Pose ton téléphone hors de la chambre ce soir.").font(.title3)
                }
                NavigationLink { PlansView() } label: {
                    Label("Préparer mes plans", systemImage: "arrow.right").font(.subheadline.weight(.medium)).frame(minHeight: 44)
                }
            }
            Button { showEpisode = true } label: {
                Label("J'ai eu un écart", systemImage: "arrow.uturn.forward").font(.subheadline).frame(maxWidth: .infinity, minHeight: 44)
            }.foregroundStyle(QuitTheme.secondary).accessibilityIdentifier("episode.open")
        }
        .navigationTitle("Aujourd'hui")
        .sheet(isPresented: $showCheckIn) { CheckInView(existing: todayCheckIn) }
        .sheet(isPresented: $showEpisode) { EpisodeView() }
    }
}
