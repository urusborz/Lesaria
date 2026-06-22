import SwiftUI
import UIKit

struct TrackerView: View {
    let mode: AppMode
    @State private var section: TrackerSection = .habits

    enum TrackerSection: String, CaseIterable {
        case habits = "Habits"
        case gebete = "Gebete"
        case cleaning = "Cleaning"
    }

    var body: some View {
        if mode == .persoenlich {
            personalTracker
        } else {
            ShoppingListView()
        }
    }

    private var personalTracker: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Tracker")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TrackerSection.allCases, id: \.rawValue) { sec in
                        Button {
                            withAnimation(.spring(response: 0.3)) { section = sec }
                        } label: {
                            Text(sec.rawValue)
                                .font(.system(size: 14, weight: section == sec ? .semibold : .regular, design: .rounded))
                                .foregroundColor(section == sec ? .white : AppTheme.textTertiary)
                                .padding(.vertical, 8).padding(.horizontal, 18)
                                .background(section == sec ? AppTheme.accentBlue.opacity(0.2) : Color.white.opacity(0.06))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(section == sec ? AppTheme.accentBlue.opacity(0.4) : AppTheme.glassBorder, lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    switch section {
                    case .habits:   HabitsView()
                    case .gebete:   GebeteView()
                    case .cleaning: CleanTrackerView()
                    }
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Habits View

struct HabitsView: View {
    @EnvironmentObject var store: DataStore
    @State private var showingAdd = false
    @State private var editing: Habit? = nil

    private var completed: Int { store.habits.filter(\.isDone).count }
    private var progress: Double { store.habits.isEmpty ? 0 : Double(completed) / Double(store.habits.count) }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                HStack {
                    SectionHeader(title: "Tägliche Habits", subtitle: "\(completed)/\(store.habits.count)")
                    AddButton { showingAdd = true }
                }
                ProgressBar(progress: progress)
            }
            .glassCard()

            if store.habits.isEmpty {
                EmptyStateView(icon: "checkmark.circle", text: "Noch keine Habits")
            } else {
                VStack(spacing: 8) {
                    ForEach(store.habits) { habit in
                        SwipeToDeleteRow(onDelete: { store.deleteHabit(id: habit.id) }) {
                            HabitRow(habit: habit)
                        }
                        .itemContextMenu(onEdit: { editing = habit },
                                         onDelete: { store.deleteHabit(id: habit.id) })
                    }
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            HabitSheet(existing: nil, isPresented: $showingAdd).environmentObject(store)
        }
        .sheet(item: $editing) { habit in
            HabitSheet(existing: habit, isPresented: Binding(
                get: { editing != nil }, set: { if !$0 { editing = nil } }
            )).environmentObject(store)
        }
    }
}

struct HabitRow: View {
    let habit: Habit
    @EnvironmentObject var store: DataStore

    var body: some View {
        HStack(spacing: 14) {
            Button { store.toggleHabit(id: habit.id) } label: {
                ZStack {
                    Circle().stroke(habit.isDone ? AppTheme.accentGreen : Color.white.opacity(0.2), lineWidth: 1.5).frame(width: 28, height: 28)
                    if habit.isDone {
                        Circle().fill(AppTheme.accentGreen.opacity(0.2)).frame(width: 28, height: 28)
                        Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(AppTheme.accentGreen)
                    }
                }
            }
            .buttonStyle(.plain)

            Text(habit.title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(habit.isDone ? AppTheme.textTertiary : AppTheme.textPrimary)
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "flame.fill").font(.system(size: 11)).foregroundColor(habit.streak > 0 ? AppTheme.accentAmber : AppTheme.textTertiary)
                Text("\(habit.streak)").font(.system(size: 12, weight: .semibold)).foregroundColor(habit.streak > 0 ? AppTheme.accentAmber : AppTheme.textTertiary)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

struct HabitSheet: View {
    let existing: Habit?
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore
    @State private var title: String

    init(existing: Habit?, isPresented: Binding<Bool>) {
        self.existing = existing
        self._isPresented = isPresented
        _title = State(initialValue: existing?.title ?? "")
    }

    var body: some View {
        DarkSheet(title: existing == nil ? "Neuer Habit" : "Habit bearbeiten", isPresented: $isPresented) {
            DarkTextField(placeholder: "Habit eingeben...", text: $title)
        } onSave: {
            guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            var h = existing ?? Habit(title: "")
            h.title = title
            if existing == nil { store.addHabit(h) } else { store.updateHabit(h) }
            isPresented = false
        }
    }
}

// MARK: - Prayer / Gebete View (live IZW Vienna times)

struct GebeteView: View {
    @EnvironmentObject var store: DataStore
    @State private var notifDenied = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let slots = store.prayerSlots(now: now)
            let next = store.nextPrayer(now: now)
            let doneCount = slots.filter { $0.isTrackable && $0.isDone }.count

            VStack(spacing: 16) {
                // Next prayer banner with live countdown
                VStack(spacing: 8) {
                    Text("Nächstes Gebet")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.accentAmber.opacity(0.8))
                    Text(next.name)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(next.date.deTime + " Uhr")
                        .font(.system(size: 20, weight: .light, design: .rounded))
                        .foregroundColor(AppTheme.accentAmber)
                    Text("in " + countdown(to: next.date, from: now))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(AppTheme.accentAmber.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusXL))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusXL).stroke(AppTheme.accentAmber.opacity(0.18), lineWidth: 0.5))

                // Progress
                VStack(spacing: 10) {
                    HStack {
                        Text("Heute gebetet")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        Text("\(doneCount)/5")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.accentGreen)
                    }
                    ProgressBar(progress: Double(doneCount) / 5.0)
                }
                .glassCard()

                // Notification toggle
                DarkToggleRow(title: "Benachrichtigungen", isOn: Binding(
                    get: { store.prayerNotificationsEnabled },
                    set: { store.setPrayerNotifications($0) }
                ))

                // Hint if notifications are disabled in iOS Settings
                if notifDenied {
                    NotificationDeniedBanner()
                }

                // Prayer list
                VStack(spacing: 1) {
                    ForEach(slots) { slot in
                        PrayerRow(slot: slot, now: now)
                            .environmentObject(store)
                    }
                }
                .background(AppTheme.glassBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusLarge).stroke(AppTheme.glassBorder, lineWidth: 0.5))

                Text("Gebetszeiten: Islamisches Zentrum Wien · 2026")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
            }
            .onAppear { NotificationManager.shared.isDenied { notifDenied = $0 } }
        }
    }

    private func countdown(to date: Date, from now: Date) -> String {
        let secs = max(0, Int(date.timeIntervalSince(now)))
        let h = secs / 3600, m = (secs % 3600) / 60, s = secs % 60
        if h > 0 { return String(format: "%d Std %02d Min", h, m) }
        return String(format: "%d Min %02d Sek", m, s)
    }
}

struct PrayerRow: View {
    let slot: PrayerSlot
    let now: Date
    @EnvironmentObject var store: DataStore

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(slot.isDone ? AppTheme.accentGreen.opacity(0.15) : (slot.isNext ? AppTheme.accentAmber.opacity(0.15) : Color.clear))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: slot.isDone ? 13 : 15, weight: slot.isDone ? .bold : .regular))
                    .foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(slot.name)
                    .font(.system(size: 16, weight: slot.isNext ? .semibold : .medium))
                    .foregroundColor(slot.isNext ? .white : (slot.isDone ? AppTheme.textTertiary : AppTheme.textPrimary))
                Text(slot.germanName)
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textTertiary)
            }
            Spacer()
            Text(slot.time.deTime)
                .font(.system(size: 16, weight: .light, design: .rounded))
                .foregroundColor(slot.isNext ? AppTheme.accentAmber : AppTheme.textSecondary)

            if slot.isTrackable {
                Button { store.togglePrayer(name: slot.name) } label: {
                    Image(systemName: slot.isDone ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(slot.isDone ? AppTheme.accentGreen : Color.white.opacity(0.2))
                }
                .buttonStyle(.plain)
            } else {
                // Sonnenaufgang: no toggle, reserve width for alignment
                Color.clear.frame(width: 20, height: 20)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(slot.isNext ? AppTheme.accentAmber.opacity(0.04) : Color.clear)
        .overlay(Divider().background(AppTheme.separator).padding(.leading, 58), alignment: .bottom)
    }

    private var icon: String {
        if !slot.isTrackable { return "sunrise.fill" }
        if slot.isDone { return "checkmark" }
        if slot.isNext { return "circle.dotted" }
        return "moon.fill"
    }
    private var iconColor: Color {
        if !slot.isTrackable { return AppTheme.accentAmber.opacity(0.6) }
        if slot.isDone { return AppTheme.accentGreen }
        if slot.isNext { return AppTheme.accentAmber }
        return AppTheme.textTertiary
    }
}

// MARK: - Clean Tracker

struct CleanTrackerView: View {
    @EnvironmentObject var store: DataStore
    @State private var showingAdd = false
    @State private var editing: CleanTask? = nil

    private var dueCount: Int { store.cleanTasks.filter { $0.isDue() }.count }
    private var total: Int { store.cleanTasks.count }
    // Progress = share of tasks currently "fresh" (not due).
    private var freshProgress: Double { total == 0 ? 0 : Double(total - dueCount) / Double(total) }

    // Due tasks first (most overdue on top), then by remaining days.
    private var sortedTasks: [CleanTask] {
        store.cleanTasks.sorted { $0.daysUntilDue() < $1.daysUntilDue() }
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                HStack {
                    SectionHeader(title: "Clean Tracker",
                                  subtitle: dueCount == 0 ? "Alles frisch" : "\(dueCount) fällig")
                    AddButton { showingAdd = true }
                }
                ProgressBar(progress: freshProgress)
            }
            .glassCard()

            if store.cleanTasks.isEmpty {
                EmptyStateView(icon: "sparkles", text: "Noch keine Aufgaben")
            } else {
                VStack(spacing: 8) {
                    ForEach(sortedTasks) { task in
                        SwipeToDeleteRow(onDelete: { store.deleteCleanTask(id: task.id) }) {
                            CleanTaskRow(task: task)
                        }
                        .itemContextMenu(onEdit: { editing = task },
                                         onDelete: { store.deleteCleanTask(id: task.id) })
                    }
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            CleanTaskSheet(existing: nil, isPresented: $showingAdd).environmentObject(store)
        }
        .sheet(item: $editing) { task in
            CleanTaskSheet(existing: task, isPresented: Binding(
                get: { editing != nil }, set: { if !$0 { editing = nil } }
            )).environmentObject(store)
        }
    }
}

struct CleanTaskRow: View {
    let task: CleanTask
    @EnvironmentObject var store: DataStore

    private var due: Bool { task.isDue() }

    private var lastDoneLabel: String {
        guard let days = task.daysSinceDone() else { return "Noch nie erledigt" }
        if days == 0 { return "Zuletzt: heute" }
        if days == 1 { return "Zuletzt: gestern" }
        return "Zuletzt: vor \(days) Tagen"
    }

    private var status: (text: String, color: Color) {
        let remaining = task.daysUntilDue()
        if task.lastDone == nil { return ("Fällig", AppTheme.accentAmber) }
        if remaining < 0  { return ("Überfällig · \(-remaining) T.", AppTheme.accentAmber) }
        if remaining == 0 { return ("Heute fällig", AppTheme.accentAmber) }
        return ("in \(remaining) T.", AppTheme.textTertiary)
    }

    var body: some View {
        HStack(spacing: 14) {
            Button { store.markCleanTaskDone(id: task.id) } label: {
                ZStack {
                    Circle().stroke(due ? AppTheme.accentAmber.opacity(0.6) : AppTheme.accentGreen, lineWidth: 1.5)
                        .frame(width: 26, height: 26)
                    if due {
                        Image(systemName: "arrow.clockwise").font(.system(size: 11, weight: .bold)).foregroundColor(AppTheme.accentAmber)
                    } else {
                        Circle().fill(AppTheme.accentGreen.opacity(0.2)).frame(width: 26, height: 26)
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(AppTheme.accentGreen)
                    }
                }
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title).font(.system(size: 15, weight: .medium)).foregroundColor(AppTheme.textPrimary)
                Text(lastDoneLabel).font(.system(size: 11)).foregroundColor(AppTheme.textTertiary)
            }
            Spacer()
            StatusPill(text: status.text, color: status.color)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

struct CleanTaskSheet: View {
    let existing: CleanTask?
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore
    @State private var title: String
    @State private var interval: Int

    init(existing: CleanTask?, isPresented: Binding<Bool>) {
        self.existing = existing
        self._isPresented = isPresented
        _title = State(initialValue: existing?.title ?? "")
        _interval = State(initialValue: existing?.intervalDays ?? 7)
    }

    var body: some View {
        DarkSheet(title: existing == nil ? "Neue Aufgabe" : "Aufgabe bearbeiten",
                  isPresented: $isPresented, detents: [.medium, .large]) {
            VStack(spacing: 14) {
                DarkTextField(placeholder: "z.B. Badezimmer putzen", text: $title)
                IntervalPicker(days: $interval)
            }
        } onSave: {
            guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            var t = existing ?? CleanTask(title: "")
            t.title = title
            t.intervalDays = interval
            if existing == nil { store.addCleanTask(t) } else { store.updateCleanTask(t) }
            isPresented = false
        }
    }
}

// MARK: - Shopping List

struct ShoppingListView: View {
    @EnvironmentObject var store: DataStore
    @State private var showingAdd = false
    @State private var editing: ShoppingItem? = nil

    private var open: [ShoppingItem] { store.shoppingItems.filter { !$0.isChecked } }
    private var done: [ShoppingItem] { store.shoppingItems.filter { $0.isChecked } }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Einkaufsliste")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("\(open.count) Artikel offen")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                if !done.isEmpty {
                    Button { store.deleteCheckedShoppingItems() } label: {
                        Text("Erledigt löschen")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textTertiary)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                AddButton { showingAdd = true }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if store.shoppingItems.isEmpty {
                        EmptyStateView(icon: "cart", text: "Einkaufsliste ist leer")
                    } else {
                        if !open.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(open) { item in
                                    SwipeToDeleteRow(onDelete: { store.deleteShoppingItem(id: item.id) }) {
                                        ShoppingRow(item: item)
                                    }
                                    .itemContextMenu(onEdit: { editing = item },
                                                     onDelete: { store.deleteShoppingItem(id: item.id) })
                                }
                            }
                        }
                        if !done.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionLabel("Erledigt")
                                ForEach(done) { item in
                                    SwipeToDeleteRow(onDelete: { store.deleteShoppingItem(id: item.id) }) {
                                        ShoppingRow(item: item)
                                    }
                                    .itemContextMenu(onEdit: { editing = item },
                                                     onDelete: { store.deleteShoppingItem(id: item.id) })
                                }
                            }
                        }
                    }
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showingAdd) {
            ShoppingSheet(existing: nil, isPresented: $showingAdd).environmentObject(store)
        }
        .sheet(item: $editing) { item in
            ShoppingSheet(existing: item, isPresented: Binding(
                get: { editing != nil }, set: { if !$0 { editing = nil } }
            )).environmentObject(store)
        }
    }
}

struct ShoppingRow: View {
    let item: ShoppingItem
    @EnvironmentObject var store: DataStore

    var body: some View {
        HStack(spacing: 14) {
            Button { store.toggleShoppingItem(id: item.id) } label: {
                ZStack {
                    Circle().stroke(item.isChecked ? AppTheme.accentGreen : Color.white.opacity(0.2), lineWidth: 1.5).frame(width: 24, height: 24)
                    if item.isChecked {
                        Circle().fill(AppTheme.accentGreen.opacity(0.15)).frame(width: 24, height: 24)
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(AppTheme.accentGreen)
                    }
                }
            }
            .buttonStyle(.plain)
            Text(item.name).font(.system(size: 15, weight: .medium))
                .foregroundColor(item.isChecked ? AppTheme.textTertiary : AppTheme.textPrimary)
                .strikethrough(item.isChecked, color: AppTheme.textTertiary)
            Spacer()
            if !item.quantity.isEmpty {
                Text(item.quantity).font(.system(size: 12)).foregroundColor(AppTheme.textTertiary)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

struct ShoppingSheet: View {
    let existing: ShoppingItem?
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore
    @State private var name: String
    @State private var quantity: String

    init(existing: ShoppingItem?, isPresented: Binding<Bool>) {
        self.existing = existing
        self._isPresented = isPresented
        _name = State(initialValue: existing?.name ?? "")
        _quantity = State(initialValue: existing?.quantity ?? "")
    }

    var body: some View {
        DarkSheet(title: existing == nil ? "Artikel hinzufügen" : "Artikel bearbeiten", isPresented: $isPresented) {
            VStack(spacing: 12) {
                DarkTextField(placeholder: "Artikel (z.B. Milch)", text: $name)
                DarkTextField(placeholder: "Menge (z.B. 2 Liter)", text: $quantity)
            }
        } onSave: {
            guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            var i = existing ?? ShoppingItem(name: "")
            i.name = name
            i.quantity = quantity
            if existing == nil { store.addShoppingItem(i) } else { store.updateShoppingItem(i) }
            isPresented = false
        }
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
    let progress: Double   // 0...1

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.06)).frame(height: 6)
                RoundedRectangle(cornerRadius: 4).fill(AppTheme.accentGreen)
                    .frame(width: max(0, min(1, progress)) * geo.size.width, height: 6)
            }
        }
        .frame(height: 6)
    }
}
