import SwiftUI

struct CheckInCalendarView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.quitAccent) private var accent
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var displayedMonth: Date
    @State private var selectedDate: Date
    @State private var showCheckIn = false

    init(date: Date = Date()) {
        // One-time navigation seed; selecting a day stays local to this screen.
        _displayedMonth = State(initialValue: date)
        _selectedDate = State(initialValue: date)
    }

    var body: some View {
        let history = CheckInHistory(checkIns: store.data.checkIns)
        let month = history.month(containing: displayedMonth)
        ScreenContent {
            HStack {
                Button("Mois précédent", systemImage: "chevron.left") { changeMonth(-1, history: history) }
                    .labelStyle(.iconOnly).frame(width: 44, height: 44)
                Spacer(minLength: 0)
                Text(month.start, format: .dateTime.month(.wide).year())
                    .font(.headline).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Button("Mois suivant", systemImage: "chevron.right") { changeMonth(1, history: history) }
                    .labelStyle(.iconOnly).frame(width: 44, height: 44)
                    .disabled(history.calendar.isDate(month.start, equalTo: history.today, toGranularity: .month))
            }
            ViewThatFits(in: .horizontal) {
                monthGrid(month, history: history)
                ScrollView(.horizontal) { monthGrid(month, history: history) }
            }
            .accessibilityIdentifier("checkin.calendar")
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) { calendarLegend }
                VStack(alignment: .leading, spacing: 8) { calendarLegend }
            }
            QuitCard {
                Text(selectedDate, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.headline).fixedSize(horizontal: false, vertical: true)
                if let checkIn = history.checkIn(on: selectedDate) {
                    CheckInSummary(checkIn: checkIn)
                } else {
                    Label("Aucun check-in enregistré", systemImage: "circle.dashed")
                        .font(.subheadline).foregroundStyle(QuitTheme.secondary)
                }
                if history.calendar.isDateInToday(selectedDate) {
                    Button(history.checkIn(on: selectedDate) == nil ? "Faire mon check-in" : "Modifier le check-in du jour") {
                        showCheckIn = true
                    }.frame(minHeight: 44)
                }
            }
            NavigationLink { JournalView(showCheckInsOnly: true) } label: {
                QuietRow(title: "Tous mes check-ins", detail: "Voir la liste dans mon journal", symbol: "book.closed", tone: .reflection)
            }.buttonStyle(.plain)
        }
        .navigationTitle("Mes check-ins").navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCheckIn) {
            CheckInView(existing: history.checkIn(on: selectedDate))
        }
    }

    private func monthGrid(_ month: CheckInMonth, history: CheckInHistory) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
            ForEach(0..<7, id: \.self) { offset in
                let weekday = (history.calendar.firstWeekday - 1 + offset) % 7
                Text(history.calendar.veryShortStandaloneWeekdaySymbols[weekday])
                    .font(.caption).foregroundStyle(QuitTheme.secondary)
                    .frame(maxWidth: .infinity)
            }
            ForEach(0..<month.leadingEmptyDays, id: \.self) { _ in
                Color.clear.frame(height: 44).accessibilityHidden(true)
            }
            ForEach(month.days, id: \.self) { day in
                calendarDay(day, history: history)
            }
        }
        .frame(minWidth: dynamicTypeSize.isAccessibilitySize ? 420 : 332, maxWidth: .infinity)
        .padding(.vertical, 2)
    }

    private func calendarDay(_ day: Date, history: CheckInHistory) -> some View {
        let selected = history.calendar.isDate(day, inSameDayAs: selectedDate)
        let recorded = history.checkIn(on: day) != nil
        let future = day > history.today
        return Button { selectedDate = day } label: {
            VStack(spacing: 4) {
                Text("\(history.calendar.component(.day, from: day))")
                    .font(.subheadline.weight(selected ? .bold : .regular)).monospacedDigit()
                Image(systemName: recorded ? "checkmark" : "minus")
                    .font(.caption2.weight(.semibold)).accessibilityHidden(true)
            }
            .foregroundStyle(selected ? accent.foreground : recorded ? accent.color : QuitTheme.secondary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(selected ? accent.color : recorded ? accent.soft : QuitTheme.surface,
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain).disabled(future)
        .accessibilityLabel(day.formatted(date: .complete, time: .omitted))
        .accessibilityValue(future ? "Date à venir" : recorded ? "Check-in enregistré" : "Aucune saisie")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
        .accessibilityIdentifier("checkin.day.\(history.calendar.component(.day, from: day))")
    }

    private var calendarLegend: some View {
        Group {
            Label("Check-in enregistré", systemImage: "checkmark").foregroundStyle(accent.color)
            Label("Aucune saisie", systemImage: "minus").foregroundStyle(QuitTheme.secondary)
        }.font(.caption).fixedSize(horizontal: true, vertical: true)
    }

    private func changeMonth(_ offset: Int, history: CheckInHistory) {
        let start = history.month(containing: displayedMonth).start
        guard let next = history.calendar.date(byAdding: .month, value: offset, to: start) else { return }
        displayedMonth = next
        selectedDate = history.calendar.isDate(next, equalTo: history.today, toGranularity: .month) ? history.today : next
    }
}

struct CheckInSummary: View {
    let checkIn: DailyCheckIn
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(checkIn.emotion.title, systemImage: checkIn.emotion.symbol).font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading),
                                     count: dynamicTypeSize.isAccessibilitySize ? 1 : 3), alignment: .leading, spacing: 12) {
                metric("Énergie", value: ["Basse", "Moyenne", "Bonne"][max(0, min(2, checkIn.energy - 1))])
                metric("Stress", value: ["Faible", "Modéré", "Élevé"][max(0, min(2, checkIn.stress - 1))])
                metric("Envie", value: "\(checkIn.urge)/10")
            }
            Label(checkIn.aligned.map { $0 ? "Objectif respecté" : "Objectif non atteint" } ?? "Objectif : pas encore de réponse",
                  systemImage: checkIn.aligned.map { $0 ? "checkmark.circle" : "circle" } ?? "questionmark.circle")
                .font(.subheadline).foregroundStyle(QuitTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }.accessibilityIdentifier("checkin.summary")
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(QuitTheme.secondary)
            Text(value).font(.subheadline.weight(.medium))
        }.fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
    }
}
