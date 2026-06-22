import SwiftUI

struct StartseitePersoenlichView: View {
    @Binding var mode: AppMode
    @Binding var selectedTab: TabItem
    @EnvironmentObject var store: DataStore

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: .now)
        switch h {
        case 5..<12:  return "Guten Morgen"
        case 12..<18: return "Guten Tag"
        case 18..<22: return "Guten Abend"
        default:      return "Gute Nacht"
        }
    }

    private var dateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_AT")
        f.dateFormat = "EEEE, d. MMMM"
        return f.string(from: .now)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dateString).font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textSecondary)
                        Text(greeting).font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(AppTheme.textPrimary)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        StatusDot(color: AppTheme.accentGreen)
                        StatusDot(color: AppTheme.accentAmber)
                        StatusDot(color: AppTheme.accentBlue)
                    }
                }
                .padding(.top, 8)

                // Daily overview (connects all daily trackers)
                dailyOverview

                // Prayer preview
                prayerPreview

                // Calendar + Reminders
                HStack(alignment: .top, spacing: 14) {
                    calendarPreview
                    remindersPreview
                }

                // Habits
                habitsPreview

                // Notes
                notesPreview

                // Clean tracker
                cleanTrackerPreview

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Daily Overview (aggregates today's progress)

    private var dailyOverview: some View {
        let slots = store.prayerSlots()
        let prayersDone = slots.filter { $0.isTrackable && $0.isDone }.count
        let habitsDone = store.habits.filter(\.isDone).count
        let habitsTotal = store.habits.count
        let cleanTotal = store.cleanTasks.count
        let cleanDue = store.cleanTasks.filter { $0.isDue() }.count
        let cleanFresh = cleanTotal - cleanDue
        let openReminders = store.personalReminders.filter { !$0.isCompleted }.count

        let totalUnits = 5 + habitsTotal
        let doneUnits = prayersDone + habitsDone
        let progress = totalUnits == 0 ? 0 : Double(doneUnits) / Double(totalUnits)

        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Heute im Überblick")
            HStack(spacing: 18) {
                CircularProgressRing(progress: progress,
                                     centerTop: "\(Int(progress * 100))%",
                                     centerBottom: "erledigt")
                VStack(spacing: 12) {
                    MiniStat(label: "Gebete", value: "\(prayersDone)/5", color: AppTheme.accentAmber)
                    MiniStat(label: "Habits", value: "\(habitsDone)/\(habitsTotal)", color: AppTheme.accentGreen)
                    MiniStat(label: "Putzen frisch", value: "\(cleanFresh)/\(cleanTotal)", color: AppTheme.accentBlue)
                    MiniStat(label: "Offene Erinnerungen", value: "\(openReminders)", color: AppTheme.accentPurple)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Prayer Preview (live IZW Vienna times, tap dots to mark done)

    private var prayerPreview: some View {
        let slots = store.prayerSlots()
        let next = store.nextPrayer()
        let trackable = slots.filter { $0.isTrackable }
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Gebete heute", subtitle: "\(trackable.filter(\.isDone).count)/5")
                Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(AppTheme.textTertiary)
            }
            .contentShape(Rectangle())
            .onTapGesture { withAnimation { selectedTab = .tracker } }

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Nächstes Gebet").font(.system(size: 11, weight: .medium)).foregroundColor(AppTheme.textTertiary)
                    Text(next.name).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(AppTheme.textPrimary)
                    Text(next.germanName).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(next.date.deTime).font(.system(size: 28, weight: .light, design: .rounded)).foregroundColor(AppTheme.accentAmber)
                    Text("Uhr").font(.system(size: 11)).foregroundColor(AppTheme.textTertiary)
                }
            }
            .padding(16)
            .background(AppTheme.accentAmber.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMedium).stroke(AppTheme.accentAmber.opacity(0.2), lineWidth: 0.5))

            HStack(spacing: 0) {
                ForEach(trackable) { prayer in
                    Button { store.togglePrayer(name: prayer.name) } label: {
                        VStack(spacing: 5) {
                            ZStack {
                                Circle().fill(prayer.isDone ? AppTheme.accentGreen.opacity(0.2) : Color.white.opacity(0.06)).frame(width: 32, height: 32)
                                Image(systemName: prayer.isDone ? "checkmark" : (prayer.isNext ? "circle.dotted" : "circle"))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(prayer.isDone ? AppTheme.accentGreen : (prayer.isNext ? AppTheme.accentAmber : AppTheme.textTertiary))
                            }
                            Text(prayer.name).font(.system(size: 10, weight: .medium)).foregroundColor(prayer.isNext ? AppTheme.accentAmber : AppTheme.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Calendar Preview

    private var calendarPreview: some View {
        let upcoming = store.upcomingEventOccurrences(store.personalEvents, from: Date(), days: 60, limit: 3)
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Termine")
            if upcoming.isEmpty {
                Text("Keine Termine").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary).padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(upcoming) { occ in
                        HStack(spacing: 10) {
                            Rectangle().fill(AppTheme.accentBlue).frame(width: 3, height: 32).clipShape(Capsule())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(occ.event.title).font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textPrimary).lineLimit(1)
                                Text(eventLabel(occ.event, occ.date)).font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .glassCard().frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { withAnimation { selectedTab = .kalender } }
    }

    // MARK: - Reminders Preview (tap circle to complete)

    private var remindersPreview: some View {
        let open = store.sortedReminders(store.personalReminders.filter { !$0.isCompleted })
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Erinnerungen")
            if open.isEmpty {
                Text("Alles erledigt").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary).padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(open.prefix(3)) { r in
                        HStack(spacing: 10) {
                            Button { store.toggleReminder(id: r.id) } label: {
                                Image(systemName: "circle").font(.system(size: 15)).foregroundColor(AppTheme.textTertiary)
                            }
                            .buttonStyle(.plain)
                            Text(r.title).font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textPrimary).lineLimit(1)
                            Spacer()
                        }
                    }
                }
            }
        }
        .glassCard().frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { withAnimation { selectedTab = .erinnerungen } }
    }

    // MARK: - Habits Preview (tap to toggle)

    private var habitsPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Tägliche Habits", subtitle: "\(store.habits.filter(\.isDone).count)/\(store.habits.count)")
                Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(AppTheme.textTertiary)
            }
            .contentShape(Rectangle())
            .onTapGesture { withAnimation { selectedTab = .tracker } }
            if store.habits.isEmpty {
                Text("Noch keine Habits").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary)
            } else {
                HStack(spacing: 10) {
                    ForEach(store.habits.prefix(4)) { habit in
                        Button { store.toggleHabit(id: habit.id) } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle().stroke(Color.white.opacity(0.1), lineWidth: 3).frame(width: 44, height: 44)
                                    if habit.isDone {
                                        Circle().fill(AppTheme.accentGreen.opacity(0.2)).frame(width: 44, height: 44)
                                        Image(systemName: "checkmark").font(.system(size: 14, weight: .bold)).foregroundColor(AppTheme.accentGreen)
                                    } else {
                                        Text("\(habit.streak)").font(.system(size: 13, weight: .semibold)).foregroundColor(AppTheme.textSecondary)
                                    }
                                }
                                Text(habit.title).font(.system(size: 11, weight: .medium)).foregroundColor(habit.isDone ? AppTheme.textPrimary : AppTheme.textTertiary).lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Notes Preview

    private var notesPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Notizen")
            if store.personalNotes.isEmpty {
                Text("Noch keine Notizen").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary)
            } else {
                HStack(spacing: 12) {
                    ForEach(store.personalNotes.prefix(2)) { note in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(note.title).font(.system(size: 14, weight: .semibold)).foregroundColor(AppTheme.textPrimary).lineLimit(1)
                            Text(note.body).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary).lineLimit(2)
                            Spacer()
                            Text(note.date.deDayMonth).font(.system(size: 10)).foregroundColor(AppTheme.textTertiary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
                        .background(AppTheme.glassBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMedium).stroke(AppTheme.glassBorder, lineWidth: 0.5))
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusLarge).stroke(AppTheme.glassBorder, lineWidth: 0.5))
        .contentShape(Rectangle())
        .onTapGesture { withAnimation { selectedTab = .notizen } }
    }

    // MARK: - Clean Tracker Preview (tap to toggle)

    private var cleanTrackerPreview: some View {
        let due = store.cleanTasks.filter { $0.isDue() }.sorted { $0.daysUntilDue() < $1.daysUntilDue() }
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Clean Tracker", subtitle: due.isEmpty ? "Alles frisch" : "\(due.count) fällig")
            if store.cleanTasks.isEmpty {
                Text("Noch keine Aufgaben").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary)
            } else if due.isEmpty {
                Text("Aktuell ist nichts fällig 🎉").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary).padding(.vertical, 4)
            } else {
                VStack(spacing: 10) {
                    ForEach(due.prefix(3)) { task in
                        HStack(spacing: 12) {
                            Button { store.markCleanTaskDone(id: task.id) } label: {
                                Image(systemName: "arrow.clockwise.circle")
                                    .font(.system(size: 16)).foregroundColor(AppTheme.accentAmber)
                            }
                            .buttonStyle(.plain)
                            Text(task.title).font(.system(size: 14, weight: .medium)).foregroundColor(AppTheme.textPrimary).lineLimit(1)
                            Spacer()
                            Text(cleanStatus(task)).font(.system(size: 11)).foregroundColor(AppTheme.accentAmber)
                        }
                    }
                }
            }
        }
        .glassCard()
        .contentShape(Rectangle())
        .onTapGesture { withAnimation { selectedTab = .tracker } }
    }

    private func cleanStatus(_ task: CleanTask) -> String {
        let r = task.daysUntilDue()
        if task.lastDone == nil { return "fällig" }
        if r < 0 { return "\(-r) T. überf." }
        return "heute"
    }

    private func eventLabel(_ event: CalendarEvent, _ date: Date) -> String {
        let day = date.deWeekdayDayMonth
        return event.hasTime ? "\(day), \(date.deTime)" : day
    }
}

struct StatusDot: View {
    let color: Color
    var body: some View { Circle().fill(color.opacity(0.7)).frame(width: 7, height: 7) }
}
