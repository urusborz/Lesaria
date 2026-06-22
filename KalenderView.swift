import SwiftUI

struct KalenderView: View {
    let mode: AppMode
    @EnvironmentObject var store: DataStore
    @State private var selectedDate = Date()
    @State private var viewMode: CalViewMode = .week
    @State private var showingAdd = false
    @State private var editing: CalendarEvent? = nil

    enum CalViewMode { case week, month }

    private var events: [CalendarEvent] {
        mode == .persoenlich ? store.personalEvents : store.familyEvents
    }
    private var accentColor: Color {
        mode == .persoenlich ? AppTheme.accentBlue : AppTheme.accentPurple
    }
    private var eventsForSelected: [EventOccurrence] {
        store.eventOccurrences(events, on: selectedDate)
    }
    private var upcoming: [EventOccurrence] {
        let startOfTomorrow = Calendar.current.date(byAdding: .day, value: 1,
                              to: Calendar.current.startOfDay(for: selectedDate)) ?? selectedDate
        return store.upcomingEventOccurrences(events, from: startOfTomorrow, days: 60, limit: 5)
    }
    // Reminders with a due date, filtered by current mode.
    private var datedReminders: [Reminder] {
        (mode == .persoenlich ? store.personalReminders : store.familyReminders).filter { $0.dueDate != nil }
    }
    private var remindersForSelected: [Reminder] {
        store.sortedReminders(datedReminders.filter {
            Calendar.current.isDate($0.dueDate!, inSameDayAs: selectedDate)
        })
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode == .persoenlich ? "Mein Kalender" : "Familienkalender")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        Text(monthYearLabel)
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    if !Calendar.current.isDateInToday(selectedDate) {
                        Button {
                            withAnimation(.spring(response: 0.3)) { selectedDate = Date() }
                        } label: {
                            Text("Heute")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(accentColor)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(accentColor.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    AddButton { showingAdd = true }
                }
                .padding(.top, 8)

                // View toggle
                HStack(spacing: 0) {
                    ViewToggleButton(title: "Woche", isSelected: viewMode == .week) {
                        withAnimation(.spring(response: 0.3)) { viewMode = .week }
                    }
                    ViewToggleButton(title: "Monat", isSelected: viewMode == .month) {
                        withAnimation(.spring(response: 0.3)) { viewMode = .month }
                    }
                }
                .background(AppTheme.controlBackground)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppTheme.glassBorder, lineWidth: 0.5))

                // Selector
                if viewMode == .week {
                    weekStrip
                } else {
                    MonthGrid(selectedDate: $selectedDate,
                              hasItems: { store.dayHasItems(events, datedReminders, on: $0) },
                              accentColor: accentColor)
                }

                // Events for selected day
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: selectedDateLabel, subtitle: "\(eventsForSelected.count) Termine")

                    if eventsForSelected.isEmpty {
                        EmptyStateView(icon: "calendar", text: "Kein Termin an diesem Tag")
                    } else {
                        ForEach(eventsForSelected) { occ in
                            EventRow(event: occ.event, date: occ.date, accentColor: accentColor)
                                .itemContextMenu(onEdit: { editing = occ.event },
                                                 onDelete: { store.deleteEvent(id: occ.event.id) })
                        }
                    }

                    // Tasks due on the selected day.
                    if !remindersForSelected.isEmpty {
                        Divider().background(AppTheme.separator).padding(.vertical, 2)
                        SectionLabel("Fällige Aufgaben")
                        ForEach(remindersForSelected) { reminder in
                            CalendarReminderRow(reminder: reminder, accentColor: accentColor)
                                .environmentObject(store)
                        }
                    }
                }
                .glassCard()

                if !upcoming.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Demnächst")
                        ForEach(upcoming) { occ in
                            EventRow(event: occ.event, date: occ.date, accentColor: accentColor, showFullDate: true)
                                .itemContextMenu(onEdit: { editing = occ.event },
                                                 onDelete: { store.deleteEvent(id: occ.event.id) })
                        }
                    }
                    .glassCard()
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, AppTheme.phoneScreenPadding)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showingAdd) {
            EventSheet(mode: mode, existing: nil, defaultDate: selectedDate, isPresented: $showingAdd)
                .environmentObject(store)
        }
        .sheet(item: $editing) { event in
            EventSheet(mode: mode, existing: event, defaultDate: event.date, isPresented: Binding(
                get: { editing != nil },
                set: { if !$0 { editing = nil } }
            ))
            .environmentObject(store)
        }
    }

    // MARK: - Week Strip

    private var weekStrip: some View {
        HStack(spacing: 6) {
            ForEach(weekDays, id: \.self) { date in
                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                let isToday = Calendar.current.isDateInToday(date)
                let hasEvent = store.dayHasItems(events, datedReminders, on: date)

                Button { withAnimation(.spring(response: 0.3)) { selectedDate = date } } label: {
                    VStack(spacing: 5) {
                        Text(dayLetter(date))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(isSelected ? .white : AppTheme.textTertiary)
                        Text(dayNumber(date))
                            .font(.system(size: 16, weight: isToday ? .bold : .regular, design: .rounded))
                            .foregroundColor(isSelected ? .white : (isToday ? accentColor : AppTheme.textPrimary))
                        Circle().fill(hasEvent ? accentColor : .clear).frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Group {
                        if isSelected { RoundedRectangle(cornerRadius: 12).fill(accentColor.opacity(0.25)) }
                    })
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .glassCard(padding: 0)
    }

    private var weekDays: [Date] {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    private var selectedDateLabel: String {
        if Calendar.current.isDateInToday(selectedDate) { return "Heute" }
        let f = DateFormatter(); f.locale = Locale(identifier: "de_AT"); f.dateFormat = "EEEE, d. MMM"
        return f.string(from: selectedDate)
    }
    private var monthYearLabel: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "de_AT"); f.dateFormat = "MMMM yyyy"
        return f.string(from: selectedDate)
    }
    private func dayLetter(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "de_AT"); f.dateFormat = "EE"
        return String(f.string(from: d).prefix(2)).uppercased()
    }
    private func dayNumber(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d"; return f.string(from: d)
    }
}

// MARK: - Month Grid

struct MonthGrid: View {
    @Binding var selectedDate: Date
    let hasItems: (Date) -> Bool
    let accentColor: Color

    private let cal = Calendar.current
    private let weekdaySymbols = ["MO","DI","MI","DO","FR","SA","SO"]

    var body: some View {
        VStack(spacing: 10) {
            // Month navigation
            HStack {
                Button { changeMonth(-1) } label: {
                    Image(systemName: "chevron.left").font(.system(size: 14, weight: .semibold)).foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                Text(monthTitle).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(AppTheme.textPrimary)
                Spacer()
                Button { changeMonth(1) } label: {
                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(.horizontal, 4)

            // Weekday header
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { s in
                    Text(s).font(.system(size: 10, weight: .medium)).foregroundColor(AppTheme.textTertiary).frame(maxWidth: .infinity)
                }
            }

            // Days grid
            let days = monthDays
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    if let day = day {
                        dayCell(day)
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
        .padding(14)
        .glassCard(padding: 0)
    }

    private func dayCell(_ date: Date) -> some View {
        let isSelected = cal.isDate(date, inSameDayAs: selectedDate)
        let isToday = cal.isDateInToday(date)
        let hasEvent = hasItems(date)
        return Button { withAnimation(.spring(response: 0.3)) { selectedDate = date } } label: {
            VStack(spacing: 3) {
                Text("\(cal.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday ? .bold : .regular, design: .rounded))
                    .foregroundColor(isSelected ? .white : (isToday ? accentColor : AppTheme.textPrimary))
                Circle().fill(hasEvent ? accentColor : .clear).frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(Group {
                if isSelected { RoundedRectangle(cornerRadius: 10).fill(accentColor.opacity(0.25)) }
            })
        }
        .buttonStyle(.plain)
    }

    private var monthTitle: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "de_AT"); f.dateFormat = "MMMM yyyy"
        return f.string(from: selectedDate)
    }

    private func changeMonth(_ delta: Int) {
        if let d = cal.date(byAdding: .month, value: delta, to: selectedDate) {
            withAnimation(.spring(response: 0.3)) { selectedDate = d }
        }
    }

    // Returns optional dates, nil for leading blanks (Monday-first).
    private var monthDays: [Date?] {
        guard let interval = cal.dateInterval(of: .month, for: selectedDate) else { return [] }
        let first = interval.start
        let dayCount = cal.range(of: .day, in: .month, for: selectedDate)?.count ?? 30
        // weekday: 1=Sun..7=Sat -> convert to Monday-first index 0..6
        let weekday = cal.component(.weekday, from: first)
        let leading = (weekday + 5) % 7
        var result: [Date?] = Array(repeating: nil, count: leading)
        for i in 0..<dayCount {
            if let d = cal.date(byAdding: .day, value: i, to: first) { result.append(d) }
        }
        return result
    }
}

// MARK: - Event Row

struct EventRow: View {
    let event: CalendarEvent
    let date: Date              // concrete occurrence date
    let accentColor: Color
    var showFullDate: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            Rectangle().fill(accentColor).frame(width: 3, height: 44).clipShape(Capsule())
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(event.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    if event.recurrence != .none {
                        Image(systemName: "repeat").font(.system(size: 10)).foregroundColor(accentColor.opacity(0.8))
                    }
                }
                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            Spacer()
            if event.hasTime && !showFullDate {
                Text(date.deTime)
                    .font(.system(size: 15, weight: .light, design: .rounded))
                    .foregroundColor(accentColor)
            }
        }
        .padding(14)
        .background(AppTheme.glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMedium).stroke(AppTheme.glassBorder, lineWidth: 0.5))
        .contentShape(Rectangle())
    }

    private var subtitle: String? {
        if showFullDate {
            return event.hasTime ? "\(date.deWeekdayDayMonth), \(date.deTime)" : date.deWeekdayDayMonth
        }
        return event.hasTime ? nil : "Ganztägig"
    }
}

// MARK: - Calendar Task Row

struct CalendarReminderRow: View {
    let reminder: Reminder
    let accentColor: Color
    @EnvironmentObject var store: DataStore

    var body: some View {
        HStack(spacing: 12) {
            Button { store.toggleReminder(id: reminder.id) } label: {
                ZStack {
                    Circle().stroke(reminder.isCompleted ? AppTheme.accentGreen : AppTheme.ringTrack, lineWidth: 1.5).frame(width: 20, height: 20)
                    if reminder.isCompleted {
                        Circle().fill(AppTheme.accentGreen).frame(width: 20, height: 20)
                        Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundColor(AppTheme.onAccent)
                    }
                }
            }
            .buttonStyle(.plain)

            Image(systemName: "bell.fill").font(.system(size: 11)).foregroundColor(accentColor.opacity(0.7))

            Text(reminder.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(reminder.isCompleted ? AppTheme.textTertiary : AppTheme.textPrimary)
                .strikethrough(reminder.isCompleted, color: AppTheme.textTertiary)
            Spacer()
            if let due = reminder.dueDate, hasTimeComponent(due) {
                Text(due.deTime).font(.system(size: 12)).foregroundColor(AppTheme.textTertiary)
            }
        }
        .padding(12)
        .background(AppTheme.glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMedium).stroke(AppTheme.glassBorder, lineWidth: 0.5))
    }

    private func hasTimeComponent(_ date: Date) -> Bool {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) != 0 || (c.minute ?? 0) != 0
    }
}

// MARK: - Event Sheet (Add + Edit)

struct EventSheet: View {
    let mode: AppMode
    let existing: CalendarEvent?
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore

    @State private var title: String
    @State private var date: Date
    @State private var hasTime: Bool
    @State private var recurrence: Recurrence

    init(mode: AppMode, existing: CalendarEvent?, defaultDate: Date, isPresented: Binding<Bool>) {
        self.mode = mode
        self.existing = existing
        self._isPresented = isPresented
        _title = State(initialValue: existing?.title ?? "")
        _date = State(initialValue: existing?.date ?? defaultDate)
        _hasTime = State(initialValue: existing?.hasTime ?? true)
        _recurrence = State(initialValue: existing?.recurrence ?? .none)
    }

    var body: some View {
        DarkSheet(title: existing == nil ? "Neuer Termin" : "Termin bearbeiten",
                  isPresented: $isPresented, detents: [.medium, .large]) {
            VStack(spacing: 14) {
                DarkTextField(placeholder: "Titel", text: $title)
                DarkToggleRow(title: "Mit Uhrzeit", isOn: $hasTime.animation())
                DatePicker("Datum",
                           selection: $date,
                           displayedComponents: hasTime ? [.date, .hourAndMinute] : [.date])
                    .datePickerStyle(.compact)
                    .colorScheme(AppTheme.appearance.preferredColorScheme)
                    .tint(AppTheme.accentBlue)
                    .padding(.horizontal, 4)
                RecurrencePicker(selection: $recurrence)
            }
        } onSave: {
            guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            var e = existing ?? CalendarEvent(title: "", date: date, isFamily: mode == .familie)
            e.title = title
            e.date = date
            e.hasTime = hasTime
            e.recurrence = recurrence
            if existing == nil { store.addEvent(e) } else { store.updateEvent(e) }
            isPresented = false
        }
    }
}

// MARK: - View Toggle Button

struct ViewToggleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? AppTheme.onAccent : AppTheme.textTertiary)
                .padding(.vertical, 8).padding(.horizontal, 22)
                .background(Group { if isSelected { Capsule().fill(AppTheme.accent).padding(3) } })
        }
        .buttonStyle(.plain)
    }
}
