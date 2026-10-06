import SwiftUI

struct TodayView: View {
    @Environment(\.quitAccent) private var accent
    @Environment(AppStore.self) private var store
    @Environment(\.quitReduceMotion) private var reduceMotion
    @State private var showCheckIn = false
    @State private var showEpisode = false
    @State private var showIntention = false
    @State private var showCheckInHelp = false
    private var todayCheckIn: DailyCheckIn? {
        CheckInHistory(checkIns: store.data.checkIns).checkIn(on: Date())
    }
    private var journeyDay: Int {
        max(1, (Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: store.data.profile.startedAt),
                                              to: Calendar.current.startOfDay(for: Date())).day ?? 0) + 1)
    }

    var body: some View {
        let checkIn = todayCheckIn
        ScreenContent {
            VStack(spacing: 8) {
                Text("Jour \(journeyDay)")
                    .font(.system(.title2, design: .rounded, weight: .medium)).foregroundStyle(accent.color)
                    .accessibilityIdentifier("today.journeyDay")
                Button { showIntention.toggle() } label: {
                    HStack(spacing: 8) {
                        Label("Ton intention", systemImage: "leaf")
                        Image(systemName: showIntention ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold)).accessibilityHidden(true)
                    }
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                }.buttonStyle(.plain).foregroundStyle(accent.color)
                    .accessibilityValue(showIntention ? "Dépliée" : "Repliée")
                    .accessibilityHint("Afficher ou masquer ton intention personnelle")
                    .accessibilityIdentifier("today.intention")
                if showIntention {
                    Text(store.data.profile.intention.isEmpty ? "Retrouver de la liberté dans mes choix." : "« \(store.data.profile.intention) »")
                        .font(.body).multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }.frame(maxWidth: .infinity)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: showIntention)
            QuitCard(tinted: true) {
                HStack {
                    Text("Mon check-in du jour").font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    if checkIn != nil { Image(systemName: "checkmark.circle.fill").foregroundStyle(accent.color) }
                    Button("À quoi sert le check-in ?", systemImage: "info.circle") { showCheckInHelp = true }
                        .labelStyle(.iconOnly).frame(width: 44, height: 44)
                        .accessibilityIdentifier("checkin.help")
                }
                if let checkIn {
                    CheckInSummary(checkIn: checkIn)
                } else {
                    Text("Note ton humeur et ton envie pour suivre leur évolution.")
                        .font(.subheadline).foregroundStyle(QuitTheme.secondary)
                }
                QuitPrimaryButton(title: checkIn == nil ? "Faire mon check-in" : "Actualiser mon check-in") { showCheckIn = true }
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("checkin.open")
                NavigationLink { CheckInCalendarView() } label: {
                    Label("Retrouver mes check-ins", systemImage: "calendar")
                        .font(.subheadline.weight(.medium)).frame(minHeight: 44)
                }.accessibilityIdentifier("checkin.history")
            }
            Button { showEpisode = true } label: {
                VStack(spacing: 4) {
                    Label("J'ai eu un écart", systemImage: "arrow.uturn.forward").font(.subheadline.weight(.medium))
                    Text("Comprendre ce qui s'est passé").font(.caption)
                }.fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, minHeight: 44)
            }.foregroundStyle(QuitTheme.secondary).accessibilityIdentifier("episode.open")
        }
        .navigationTitle("Aujourd'hui")
        .sheet(isPresented: $showCheckIn) { CheckInView(existing: checkIn) }
        .sheet(isPresented: $showEpisode) { EpisodeView() }
        .sheet(isPresented: $showCheckInHelp) { CheckInHelpView() }
    }
}
