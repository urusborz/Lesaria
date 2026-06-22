import SwiftUI
import UIKit

struct TrackerView: View {
    let mode: AppMode
    @Binding var section: TrackerSection

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
            .padding(.horizontal, AppTheme.phoneScreenPadding)
            .padding(.top, 8)
            .padding(.bottom, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TrackerSection.allCases, id: \.rawValue) { sec in
                        Button {
                            withAnimation(.spring(response: 0.3)) { section = sec }
                        } label: {
                            Text(sec.title)
                                .font(.system(size: 14, weight: section == sec ? .semibold : .regular, design: .rounded))
                                .foregroundColor(section == sec ? AppTheme.onAccent : AppTheme.textTertiary)
                                .padding(.vertical, 8).padding(.horizontal, 18)
                                .background {
                                    if section == sec {
                                        AppTheme.accent
                                    } else {
                                        AppTheme.controlBackground
                                    }
                                }
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(section == sec ? AppTheme.accent.opacity(0.4) : AppTheme.glassBorder, lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.phoneScreenPadding)
            }
            .padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    switch section {
                    case .habits:   HabitsView()
                    case .gebete:   GebeteView()
                    case .entzug: WithdrawalTrackerView()
                    }
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, AppTheme.phoneScreenPadding)
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
                    Circle().stroke(habit.isDone ? AppTheme.accentGreen : AppTheme.ringTrack, lineWidth: 1.5).frame(width: 28, height: 28)
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
                        .foregroundColor(AppTheme.textPrimary)
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
                        .foregroundColor(slot.isNext ? AppTheme.textPrimary : (slot.isDone ? AppTheme.textTertiary : AppTheme.textPrimary))
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
                        .foregroundColor(slot.isDone ? AppTheme.accentGreen : AppTheme.ringTrack)
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

// MARK: - Withdrawal Tracker

struct WithdrawalTrackerView: View {
    @EnvironmentObject var store: DataStore
    @State private var showingAdd = false
    @State private var editing: WithdrawalItem? = nil

    private var sortedItems: [WithdrawalItem] {
        store.withdrawalItems.sorted { $0.cleanHours() > $1.cleanHours() }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    SectionHeader(title: "Entzug", subtitle: "\(store.withdrawalItems.count) aktiv")
                    Text("Tracke Abstinenz, Gründe, Ziele und Rückfälle.")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }
                AddButton { showingAdd = true }
            }
            .glassCard()

            if sortedItems.isEmpty {
                EmptyStateView(icon: "flame", text: "Noch kein Entzug angelegt")
            } else {
                VStack(spacing: 10) {
                    ForEach(sortedItems) { item in
                        SwipeToDeleteRow(onDelete: { store.deleteWithdrawalItem(id: item.id) }) {
                            WithdrawalCard(item: item, onEdit: { editing = item })
                        }
                        .itemContextMenu(onEdit: { editing = item },
                                         onDelete: { store.deleteWithdrawalItem(id: item.id) })
                    }
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            WithdrawalSheet(existing: nil, isPresented: $showingAdd).environmentObject(store)
        }
        .sheet(item: $editing) { item in
            WithdrawalSheet(existing: item, isPresented: Binding(
                get: { editing != nil }, set: { if !$0 { editing = nil } }
            )).environmentObject(store)
        }
    }
}

struct WithdrawalCard: View {
    let item: WithdrawalItem
    let onEdit: () -> Void
    @EnvironmentObject var store: DataStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Seit \(item.startDate.deDayMonth)")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textTertiary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(item.cleanDays())")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.accentAmber)
                    Text(item.cleanDays() == 1 ? "Tag" : "Tage")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }

            if !item.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                infoLine(title: "Warum", text: item.reason)
            }
            if !item.goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                infoLine(title: "Ziel", text: item.goal)
            }

            HStack(spacing: 8) {
                StatusPill(text: "\(item.relapses.count) Rückfälle", color: item.relapses.isEmpty ? AppTheme.accentGreen : AppTheme.accentAmber)
                Spacer()
                Button("Bearbeiten", action: onEdit)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(AppTheme.controlBackground)
                    .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                Button {
                    store.logRelapse(id: item.id, resetStreak: false)
                } label: {
                    relapseButton("Rückfall notieren", icon: "exclamationmark.circle")
                }
                Button {
                    store.logRelapse(id: item.id, resetStreak: true)
                } label: {
                    relapseButton("Neu starten", icon: "arrow.clockwise")
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardSolid)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusLarge).stroke(AppTheme.glassBorder, lineWidth: 0.5))
        .contentShape(Rectangle())
    }

    private func infoLine(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(AppTheme.textTertiary)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func relapseButton(_ text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text).lineLimit(1).minimumScaleFactor(0.75)
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(AppTheme.onAccent)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AppTheme.accent)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
    }
}

struct WithdrawalSheet: View {
    let existing: WithdrawalItem?
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore
    @State private var title: String
    @State private var reason: String
    @State private var goal: String
    @State private var startDate: Date

    init(existing: WithdrawalItem?, isPresented: Binding<Bool>) {
        self.existing = existing
        self._isPresented = isPresented
        _title = State(initialValue: existing?.title ?? "")
        _reason = State(initialValue: existing?.reason ?? "")
        _goal = State(initialValue: existing?.goal ?? "")
        _startDate = State(initialValue: existing?.startDate ?? Date())
    }

    var body: some View {
        DarkSheet(title: existing == nil ? "Neuer Entzug" : "Entzug bearbeiten",
                  isPresented: $isPresented, detents: [.large]) {
            VStack(spacing: 12) {
                DarkTextField(placeholder: "Womit willst du aufhören?", text: $title)
                DarkTextEditor(placeholder: "Warum hörst du auf?", text: $reason)
                DarkTextEditor(placeholder: "Was ist dein Ziel?", text: $goal)
                DatePicker("Startdatum", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .colorScheme(AppTheme.appearance.preferredColorScheme)
                    .tint(AppTheme.accentBlue)
                    .padding(.horizontal, 4)
            }
        } onSave: {
            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            var item = existing ?? WithdrawalItem(title: title)
            item.title = title
            item.reason = reason
            item.goal = goal
            item.startDate = startDate
            if existing == nil { store.addWithdrawalItem(item) } else { store.updateWithdrawalItem(item) }
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
                            .background(AppTheme.controlBackground)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                AddButton { showingAdd = true }
            }
            .padding(.horizontal, AppTheme.phoneScreenPadding)
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
                .padding(.horizontal, AppTheme.phoneScreenPadding)
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
                    Circle().stroke(item.isChecked ? AppTheme.accentGreen : AppTheme.ringTrack, lineWidth: 1.5).frame(width: 24, height: 24)
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
                RoundedRectangle(cornerRadius: 4).fill(AppTheme.ringTrack).frame(height: 6)
                RoundedRectangle(cornerRadius: 4).fill(AppTheme.accentGreen)
                    .frame(width: max(0, min(1, progress)) * geo.size.width, height: 6)
            }
        }
        .frame(height: 6)
    }
}
